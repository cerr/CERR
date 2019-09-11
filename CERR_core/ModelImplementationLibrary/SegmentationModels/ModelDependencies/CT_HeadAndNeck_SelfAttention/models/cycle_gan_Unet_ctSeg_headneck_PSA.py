import numpy as np
import torch
import os
from collections import OrderedDict
from torch.autograd import Variable
import itertools
import util.util as util
from util.image_pool import ImagePool
from .base_model import BaseModel
from . import networks
import sys

import torch.nn.functional as F

import torch.nn as nn



class CustomSoftDiceLoss(nn.Module):
    def __init__(self, n_classes, class_ids):
        super(CustomSoftDiceLoss, self).__init__()
        self.one_hot_encoder = One_Hot(n_classes).forward
        self.n_classes = n_classes
        self.class_ids = class_ids

    def forward(self, input, target):
        smooth = 0.01
        batch_size = input.size(0)

        input = F.softmax(input[:,self.class_ids], dim=1).view(batch_size, len(self.class_ids), -1)
        target = self.one_hot_encoder(target).contiguous().view(batch_size, self.n_classes, -1)
        target = target[:, self.class_ids, :]

        inter = torch.sum(input * target, 2) + smooth
        union = torch.sum(input, 2) + torch.sum(target, 2) + smooth

        score = torch.sum(2.0 * inter / union)
        score = 1.0 - score / (float(batch_size) * float(self.n_classes))

        return score


class DiceLoss(nn.Module):
    def __init__(self):
        super().__init__()

    def forward(self, pred_stage1, target):
        """
        :param pred_stage1: (B, 9,  256, 256)
        :param pred_stage2: (B, 9, 256, 256)
        :param target: (B, 256, 256)
        :return: Dice
        """

        # 
        organ_target = torch.zeros((target.size(0), num_organ,  256, 256))

        for organ_index in range(1, num_organ + 1):
            temp_target = torch.zeros(target.size())
            temp_target[target == organ_index] = 1
            organ_target[:, organ_index - 1, :, :, :] = temp_target
            # organ_target: (B, 8,  128, 128)

        organ_target = organ_target.cuda()

        # loss
        dice_stage1 = 0.0

        for organ_index in range(1, num_organ + 1):
            dice_stage1 += 2 * (pred_stage1[:, organ_index, :, :, :] * organ_target[:, organ_index - 1, :, :, :]).sum(dim=1).sum(dim=1).sum(
                dim=1) / (pred_stage1[:, organ_index, :, :, :].pow(2).sum(dim=1).sum(dim=1).sum(dim=1) +
                          organ_target[:, organ_index - 1, :, :, :].pow(2).sum(dim=1).sum(dim=1).sum(dim=1) + 1e-5)

        dice_stage1 /= num_organ


        # 
        dice = dice_stage1 

        # 
        return (1 - dice).mean()





class cycle_gan_unet_ct_seg_baseline(BaseModel):
    def name(self):
        return 'cycle_gan_unet_ct_seg_baseline'

    def initialize(self, opt):
        BaseModel.initialize(self, opt)

        nb = opt.batchSize
        size = opt.fineSize
        self.input_A = self.Tensor(nb, opt.input_nc, size, size) # input A
        self.input_B = self.Tensor(nb, opt.output_nc, size, size) # input B


        self.input_A_y = self.Tensor(nb, opt.output_nc, size, size) # input B
        self.input_B_y = self.Tensor(nb, opt.output_nc, size, size) # input B
        self.input_A=self.input_A.cuda()
        self.input_B=self.input_B.cuda()
        self.input_A_y=self.input_A_y.cuda()
        self.input_B_y=self.input_B_y.cuda()

        self.test_A = self.Tensor(nb, opt.output_nc, size, size) # input B
        self.test_AB = self.Tensor(nb, opt.output_nc, size, size) # input B        
        self.test_A_y = self.Tensor(nb, opt.output_nc, size, size) # input B     
        self.num_organ=6 #/->6 ->8 
        

        '''
        BSA is put in the last layer
             
        networks.get_Unet_Block_SA_inter_intra(intput_channel,organ_number,initialize_type,gpu_id,B,S,K)

        B is the block size, S is the stride size, K is the kernel size
        '''

        if opt.location == 'last':
            self.netSeg_A=networks.get_Unet_Block_SA_inter_intra_wd_stride_kernel(1,self.num_organ+1,opt.init_type,self.gpu_ids,opt.B,opt.S,opt.K)
        if opt.location == 'penultimate': 
            self.netSeg_A=networks.get_Unet_Block_SA_inter_intra_wd_stride_kernel_second_layer(1,self.num_organ+1,opt.init_type,self.gpu_ids,opt.B,opt.S,opt.K)
        


        #print ('params is ',params)
        #print ('flops is ',flops)
        self.criterion = nn.CrossEntropyLoss()
        if self.isTrain:
            use_sigmoid = opt.no_lsgan
            

            #below use the default SegNet
            #self.netSeg_A=networks.define_Seg(2, opt.output_nc, opt.ngf, opt.which_model_netSeg, opt.norm, not opt.no_dropout, opt.init_type, self.gpu_ids)
            
            #self.netSeg_B=networks.define_Seg(1, opt.output_nc, opt.ngf, opt.which_model_netSeg, opt.norm, not opt.no_dropout, opt.init_type, self.gpu_ids)
            ## below use Unet
            #self.netSeg_A=networks.get_Unet(1,1,opt.init_type,self.gpu_ids)
            self.netSeg_B=networks.get_Unet(1,1,opt.init_type,self.gpu_ids)

        if not self.isTrain or opt.continue_train:
            which_epoch = opt.which_epoch
            #self.load_network(self.netG_A, 'G_A', which_epoch)
            #self.load_network(self.netG_B, 'G_B', which_epoch)

            if self.isTrain:

                self.load_network(self.netSeg_A,'Seg_A',which_epoch)
                self.load_network(self.netSeg_B,'Seg_B',which_epoch)

        if self.isTrain:
            self.old_lr = opt.lr
            self.fake_A_pool = ImagePool(opt.pool_size)
            self.fake_B_pool = ImagePool(opt.pool_size)

            #self.load_network(self.netSeg_A,'Seg_A',opt.Load_CT_Weight_Seg_A)
            # define loss functions
            #self.criterionGAN = networks.GANLoss(use_lsgan=not opt.no_lsgan, tensor=self.Tensor)
            self.criterionCycle = torch.nn.L1Loss()
            self.criterionIdt = torch.nn.L1Loss()
            # initialize optimizers
            #self.optimizer_G = torch.optim.Adam(itertools.chain(self.netG_A.parameters(), self.netG_B.parameters()),
            #                                    lr=opt.lr, betas=(opt.beta1, 0.999))
            #self.optimizer_D_A = torch.optim.Adam(self.netD_A.parameters(), lr=opt.lr, betas=(opt.beta1, 0.999))
            #self.optimizer_D_B = torch.optim.Adam(self.netD_B.parameters(), lr=opt.lr, betas=(opt.beta1, 0.999))
            self.optimizer_Seg_A = torch.optim.Adam(self.netSeg_A.parameters(), lr=opt.lr, betas=(opt.beta1, 0.999),amsgrad=True)
            self.optimizer_Seg_B = torch.optim.Adam(self.netSeg_B.parameters(), lr=opt.lr, betas=(opt.beta1, 0.999),amsgrad=True)
            if opt.optimizer == 'SGD':
                self.optimizer_Seg_A = torch.optim.SGD(self.netSeg_A.parameters(), lr=opt.lr, momentum=0.99)
                self.optimizer_Seg_B = torch.optim.SGD(self.netSeg_B.parameters(), lr=opt.lr, momentum=0.99)
            self.optimizers = []
            self.schedulers = []
            #self.optimizers.append(self.optimizer_G)
            #self.optimizers.append(self.optimizer_D_A)
            #self.optimizers.append(self.optimizer_D_B)
            self.optimizers.append(self.optimizer_Seg_A)
            self.optimizers.append(self.optimizer_Seg_B)            
            for optimizer in self.optimizers:
                self.schedulers.append(networks.get_scheduler(optimizer, opt))

        print('---------- Networks initialized -------------')
        #networks.print_network(self.netG_A)
        #networks.print_network(self.netG_B)
        if self.isTrain:
            #networks.print_network(self.netD_A)
            #networks.print_network(self.netD_B)
            networks.print_network(self.netSeg_A)
            #networks.print_network(self.netSeg_B)            
        print('-----------------------------------------------')
    def set_test_input(self,input):
        input_A1=input[0]
        self.test_A,self.test_A_y=torch.split(input_A1, input_A1.size(0), dim=1)    
        #self.test_A=input_A1
        
    def net_G_A_load_weight(self,weight):
        self.load_network(self.netG_A, 'G_A', weight)

    def net_G_A2B_test(self):
        self.fake_A2B=self.netG_A(self.test_A)
        self.fake_A2B=self.fake_A2B.data
        self.fake_A2B_A_img, output_fakeA2B=self.tensor2im_jj(self.fake_A2B)

        return self.fake_A2B_A_img,output_fakeA2B

    def cross_entropy_2D(input, target, weight=None, size_average=True):
        n, c, h, w = input.size()
        log_p = F.log_softmax(input, dim=1)
        log_p = log_p.transpose(1, 2).transpose(2, 3).contiguous().view(-1, c)
        target = target.view(target.numel())
        loss = F.nll_loss(log_p, target, weight=weight, size_average=False)
        if size_average:
            loss /= float(target.numel())
        return loss


    def dice_loss(self,input, target):


        #log_p = F.softmax(input, dim=1)
        #target=target.long()
        #target=target.view(target.size()[0],256,256)
        #log_p=Variable(log_p, requires_grad = True)
        #loss=self.criterion(log_p, torch.max(target, 1)[1])       
        #loss=self.criterion(log_p, target)
        #loss /= float(target.numel())        

        ##USE for CrossEntrophy
        if 1>0:    
            n, c, h, w = input.size()
            input=input.float()
            log_p = F.log_softmax(input,dim=1)
            log_p = log_p.transpose(1, 2).transpose(2, 3).contiguous().view(-1, c)
            target = target.view(target.numel())
            target=target.long()
            loss = F.nll_loss(log_p, target, weight=None, size_average=False)
            size_average=False
            if size_average:
                loss /= float(target.numel())
        else:
            loss=self.CrossEntropy2d_Ohem(input,target)
        ## End for CrossEntrophy


        #dsc_loss=SoftDiceLoss(9)
        #loss=dsc_loss(input,target)


        return loss
        #if size_average:
        
        #loss = Variable(loss, requires_grad = True)
    #    return loss

    def get_curr_lr(self):
        self.cur_lr=self.optimizer_Seg_A.param_groups[0]['lr'] 

        return self.cur_lr
    def dice_loss_mt_dc(self,pred_stage1, target):
        """
        :param pred_stage1: (B, 9,  256, 256)
        :param pred_stage2: (B, 9, 256, 256)
        :param target: (B, 256, 256)
        :return: Dice
        """
        organ_target = torch.zeros((target.size(0), self.num_organ+1,  256, 256))  # 8+1
        #print ('dd ',pred_stage1.shape)
        pred_stage1=F.softmax(pred_stage1,dim=1)

        for organ_index in range(self.num_organ + 1):
            temp_target = torch.zeros(target.size())
            temp_target[target == organ_index] = 1
            #print (temp_target.shape)
            #print (organ_target[:, organ_index, :, :].shape)
            organ_target[:, organ_index,  :, :] = temp_target.reshape(temp_target.shape[0],256,256)
            # organ_target: (B, 8,  128, 128)

        organ_target = organ_target.cuda()

            # loss
        dice_stage1 = 0.0   
        smooth = 1.
        for organ_index in  range(self.num_organ + 1):
            #print (pred_stage1.shape)
            #print (organ_target.shape)
            pred_tep=pred_stage1[:, organ_index,  :, :] 
            target_tep=organ_target[:, organ_index,  :, :]
            #pred_tep=pred_stage1[:, 0,  :, :]   # move back
            #target_tep=organ_target[:, 0,  :, :] # move back


            #print (pred_tep.size())
            #print (target.size())
            pred_tep=pred_tep.contiguous().view(-1)
            target_tep=target_tep.contiguous().view(-1)
            intersection_tp = (pred_tep * target_tep).sum()
            dice_tp=(2. * intersection_tp + smooth)/(pred_tep.sum() + target_tep.sum() + smooth)
            

            dice_stage1=dice_stage1+dice_tp
        dice_stage1 /= (self.num_organ+1)
        dice = dice_stage1 
        return (1 - dice)#.mean()

    def cal_dice_loss(self,pred_stage1, target):
        """
        :param pred_stage1: (B, 9,  256, 256)
        :param pred_stage2: (B, 9, 256, 256)
        :param target: (B, 256, 256)
        :return: Dice
        """
        organ_target = torch.zeros((target.size(0), self.num_organ+1,  256, 256))  # 8+1
        #print ('dd ',pred_stage1.shape)
        pred_stage1=F.softmax(pred_stage1,dim=1)

        for organ_index in range(self.num_organ + 1):
            temp_target = torch.zeros(target.size())
            temp_target[target == organ_index] = 1
            #print (temp_target.shape)
            #print (organ_target[:, organ_index, :, :].shape)
            organ_target[:, organ_index,  :, :] = temp_target.reshape(temp_target.shape[0],256,256)
            # organ_target: (B, 8,  128, 128)

        organ_target = organ_target.cuda()

            # loss
        dice_0=0
        dice_1=0
        dice_2=0
        dice_3=0
        dice_4=0
        dice_5=0
        dice_6=0
        dice_7=0
        dice_8=0

        dice_stage1 = 0.0   
        smooth = 1.
        for organ_index in  range(self.num_organ + 1):
            #print (pred_stage1.shape)
            #print (organ_target.shape)
            pred_tep=pred_stage1[:, organ_index,  :, :] 
            target_tep=organ_target[:, organ_index,  :, :]
            #pred_tep=pred_stage1[:, 0,  :, :]   # move back
            #target_tep=organ_target[:, 0,  :, :] # move back


            #print (pred_tep.size())
            #print (target.size())
            pred_tep=pred_tep.contiguous().view(-1)
            target_tep=target_tep.contiguous().view(-1)
            intersection_tp = (pred_tep * target_tep).sum()
            dice_tp=(2. * intersection_tp + smooth)/(pred_tep.sum() + target_tep.sum() + smooth)
            
            if organ_index==0:
                dice_0=dice_tp
            if organ_index==1:
                dice_1=dice_tp
            if organ_index==2:
                dice_2=dice_tp
            if organ_index==3:
                dice_3=dice_tp
            if organ_index==4:
                dice_4=dice_tp
            if organ_index==5:
                dice_5=dice_tp
            if organ_index==6:
                dice_6=dice_tp
            if organ_index==7:
                dice_7=dice_tp
            if organ_index==8:
                dice_8=dice_tp
            if organ_index==9:
                dice_9=dice_tp





        #print (dice_0)
        #print (dice_1)
        #print (dice_7)
        return dice_0,dice_1,dice_2,dice_3,dice_4,dice_5,dice_6,dice_7,dice_8

        #return dice_0.data,dice_1.data,dice_2.data,dice_3.data,dice_4.data,dice_5.data,dice_6.data,dice_7.data,dice_8.data


    def cal_dice_loss_PDDA_val(self,pred_stage1, target):
        """
        :param pred_stage1: (B, 9,  256, 256)
        :param pred_stage2: (B, 9, 256, 256)
        :param target: (B, 256, 256)
        :return: Dice
        """
        organ_target = torch.zeros((target.size(0), self.num_organ+1,  256, 256))  # 8+1
        #print ('dd ',pred_stage1.shape)
        pred_stage1=F.softmax(pred_stage1,dim=1)
            # loss
        dice_0=0
        dice_1=0
        dice_2=0
        dice_3=0
        dice_4=0
        dice_5=0
        dice_6=0
        dice_7=0
        dice_8=0

        
        return dice_0,dice_1,dice_2,dice_3,dice_4,dice_5,dice_6,dice_7,dice_8

        #return dice_0.data,dice_1.data,dice_2.data,dice_3.data,dice_4.data,dice_5.data,dice_6.data,dice_7.data,dice_8.data

    def set_test_input(self,input):
        input_A1=input[0]
        self.test_A,self.test_A_y=torch.split(input_A1, input_A1.size(0), dim=1)    
        
    def net_G_A_A2B_Segtest_image(self):
        self.test_A=self.test_A.cuda()
        self.test_AB=self.test_AB.cuda()
        self.test_A_y=self.test_A_y.cuda()
        #self.test_AB=self.netG_A(self.test_A)
        test_img=self.test_A
        #test_img=torch.cat((self.test_A,self.test_AB),1)
        #print (self.test_A.size())
        #print (self.test_AB.size())
        #print (test_img.size())
        test_img=test_img.float()
        A_AB_seg,_,global_map=self.netSeg_A(test_img)
        #A_AB_seg=F.softmax(A_AB_seg,dim=1)
        loss=self.dice_loss(A_AB_seg,self.test_A_y)
        #print (A_AB_seg.size())

        A_AB_seg=F.softmax(A_AB_seg, dim=1)

        LP_map=A_AB_seg[:,1,:,:]
        RP_map=A_AB_seg[:,2,:,:]
        RP_map=RP_map.view(1,1,256,256)
        LP_map=LP_map.view(1,1,256,256)
        RP_map=RP_map.data
        LP_map=LP_map.data
        global_map=global_map.data
        

        A_AB_seg=torch.argmax(A_AB_seg, dim=1)
        A_AB_seg=A_AB_seg.view(1,1,256,256)
        A_AB_seg_out=A_AB_seg.data
        #print (A_AB_seg_out.size())
        #A_AB_seg_out=torch.argmax(A_AB_seg_out, dim=1)
        A_AB_seg_out=A_AB_seg_out.view(1,1,256,256)
        #print (A_AB_seg_out.size())
        A_y_out=self.test_A_y.data
        self.test_A_y=self.test_A_y.cuda()


        test_A_data=self.test_A.data
        #test_AB=self.test_AB.data
        A_AB_seg=A_AB_seg.data
        A_y=self.test_A_y.data
        test_A_data,d999=self.tensor2im_jj(test_A_data)
        LP_map_data,d999=self.tensor2im_jj(LP_map)
        RP_map_data,d999=self.tensor2im_jj(RP_map)
        #global_map,d999=self.tensor2im_jj(global_map)
        #test_AB,d2=self.tensor2im_jj(test_AB)
        A_AB_seg=util.tensor2im_hd_neck(A_AB_seg)
        A_y=util.tensor2im_hd_neck(A_y)
        #print (test_A_data.shape)
        #print (test_AB.shape)
        #print (A_AB_seg.shape)

        test_A_data=test_A_data[:,256:512,:]
        LP_map_data=LP_map_data[:,256:512,:]
        RP_map_data=RP_map_data[:,256:512,:]
        #global_map=global_map[:,256:512,:]
        #test_AB=test_AB[:,256:512,:]
        A_AB_seg=A_AB_seg#[:,256:512,:]
        A_y=A_y#[:,256:512,:]

        #test_A_data=test_A_data[:,512:1024,:]
        #test_AB=test_AB[:,512:1024,:]
        #A_AB_seg=A_AB_seg[:,512:1024,:]
        #A_y=A_y[:,512:1024,:]

        image_numpy_all=np.concatenate((test_A_data,A_y,),axis=1)
        #image_numpy_all=np.concatenate((image_numpy_all,A_y,),axis=1)        
        image_numpy_all=np.concatenate((image_numpy_all,A_AB_seg,),axis=1)
        #image_numpy_all=np.concatenate((image_numpy_all,global_map,),axis=1)
        image_numpy_all=np.concatenate((image_numpy_all,LP_map_data,),axis=1)
        image_numpy_all=np.concatenate((image_numpy_all,RP_map_data,),axis=1)
        #self.fake_A2B=self.fake_A2B.data
        #self.fake_A2B_A_img, output_fakeA2B=self.tensor2im_jj(self.fake_A2B)
        #print (loss)
        return loss,self.test_A.cpu().float().numpy(),A_AB_seg_out.cpu().float().numpy(),A_y_out.cpu().float().numpy(),image_numpy_all
        
        #return loss,self.test_A.cpu().float().numpy(),A_AB_seg_out.cpu().float().numpy(),A_y_out.cpu().float().numpy(),image_numpy_all,d0,d1,d2,d3,d4,d5,d6,d7,d8,LP_map.cpu().float().numpy(),RP_map.cpu().float().numpy()
        
        #return tep_dice_loss,ori_img,seg,gt,image_numpy,d0,d1,d2,d3,d4,d5,d6,d7,d8

    def net_G_A_A2B_Segtest_image_varian(self):
        self.test_A=self.test_A.cuda()
        self.test_AB=self.test_AB.cuda()
        self.test_A_y=self.test_A_y.cuda()
        #self.test_AB=self.netG_A(self.test_A)
        test_img=self.test_A
        #test_img=torch.cat((self.test_A,self.test_AB),1)
        #print (self.test_A.size())
        #print (self.test_AB.size())
        #print (test_img.size())
        test_img=test_img.float()
        A_AB_seg=self.netSeg_A(test_img)
        #A_AB_seg=F.softmax(A_AB_seg,dim=1)
        loss=self.dice_loss(A_AB_seg,self.test_A_y)
        #print (A_AB_seg.size())

        A_AB_seg=F.softmax(A_AB_seg, dim=1)

        LP_map=A_AB_seg[:,1,:,:]
        RP_map=A_AB_seg[:,2,:,:]
        LS_map=A_AB_seg[:,3,:,:]
        RS_map=A_AB_seg[:,4,:,:]
        LBP_map=A_AB_seg[:,5,:,:]
        RBP_map=A_AB_seg[:,6,:,:]
        Sub_map=A_AB_seg[:,7,:,:]
        Spine_map=A_AB_seg[:,8,:,:]

        RP_map=RP_map.view(1,1,256,256)
        LP_map=LP_map.view(1,1,256,256)
        LS_map=LS_map.view(1,1,256,256)
        RS_map=RS_map.view(1,1,256,256)
        Sub_map=Sub_map.view(1,1,256,256)
        LBP_map=LBP_map.view(1,1,256,256)
        RBP_map=RBP_map.view(1,1,256,256)
        Spine_map=Spine_map.view(1,1,256,256)

        RP_map=RP_map.data
        LP_map=LP_map.data
        LS_map=LS_map.data
        RS_map=RS_map.data
        Sub_map=Sub_map.data
        LBP_map=LBP_map.data
        RBP_map=RBP_map.data
        Spine_map=Spine_map.data



        RP_map_tp=RP_map
        RP_map_tp=RP_map_tp+LP_map
        RP_map_tp=RP_map_tp+LS_map
        RP_map_tp=RP_map_tp+RS_map
        RP_map_tp=RP_map_tp+Sub_map
        RP_map_tp=RP_map_tp+LBP_map
        RP_map_tp=RP_map_tp+RBP_map
        RP_map_tp=RP_map_tp+Spine_map
        
        d0,d1,d2,d3,d4,d5,d6,d7,d8=self.cal_dice_loss_PDDA_val(A_AB_seg,self.test_A_y)

        A_AB_seg=torch.argmax(A_AB_seg, dim=1)
        A_AB_seg=A_AB_seg.view(1,1,256,256)
        A_AB_seg_out=A_AB_seg.data
        #print (A_AB_seg_out.size())
        #A_AB_seg_out=torch.argmax(A_AB_seg_out, dim=1)
        A_AB_seg_out=A_AB_seg_out.view(1,1,256,256)
        #print (A_AB_seg_out.size())
        A_y_out=self.test_A_y.data
        self.test_A_y=self.test_A_y.cuda()


        test_A_data=self.test_A.data
        #test_AB=self.test_AB.data
        A_AB_seg=A_AB_seg.data
        A_y=self.test_A_y.data
        test_A_data,d999=self.tensor2im_jj(test_A_data)
        LP_map_data,d999=self.tensor2im_jj(LP_map)
        RP_map_data,d999=self.tensor2im_jj(RP_map)
        RP_map_tp_data,d999=self.tensor2im_jj(RP_map_tp)
        #test_AB,d2=self.tensor2im_jj(test_AB)
        A_AB_seg=util.tensor2im_hd_neck(A_AB_seg)
        A_y=util.tensor2im_hd_neck(A_y)
        #print (test_A_data.shape)
        #print (test_AB.shape)
        #print (A_AB_seg.shape)

        test_A_data=test_A_data[:,256:512,:]
        LP_map_data=LP_map_data[:,256:512,:]
        RP_map_data=RP_map_data[:,256:512,:]
        RP_map_tp_data=RP_map_tp_data[:,256:512,:]
        #test_AB=test_AB[:,256:512,:]
        A_AB_seg=A_AB_seg#[:,256:512,:]
        A_y=A_y#[:,256:512,:]

        #test_A_data=test_A_data[:,512:1024,:]
        #test_AB=test_AB[:,512:1024,:]
        #A_AB_seg=A_AB_seg[:,512:1024,:]
        #A_y=A_y[:,512:1024,:]

        image_numpy_all=np.concatenate((test_A_data,A_y,),axis=1)
        #image_numpy_all=np.concatenate((image_numpy_all,A_y,),axis=1)        
        image_numpy_all=np.concatenate((image_numpy_all,A_AB_seg,),axis=1)
        #image_numpy_all=np.concatenate((image_numpy_all,LP_map_data,),axis=1)
        #RP_map_data=RP_map_data+LP_map_data
        image_numpy_all=np.concatenate((image_numpy_all,RP_map_tp_data,),axis=1)
        #self.fake_A2B=self.fake_A2B.data
        #self.fake_A2B_A_img, output_fakeA2B=self.tensor2im_jj(self.fake_A2B)
        #print (loss)
        return loss,self.test_A.cpu().float().numpy(),A_AB_seg_out.cpu().float().numpy(),A_y_out.cpu().float().numpy(),image_numpy_all,d0,d1,d2,d3,d4,d5,d6,d7,d8,LP_map.cpu().float().numpy(),RP_map.cpu().float().numpy(),LS_map.cpu().float().numpy(),RS_map.cpu().float().numpy(),Sub_map.cpu().float().numpy(),RP_map_tp.cpu().float().numpy()



    def set_input(self, input):
        AtoB = self.opt.which_direction == 'AtoB'
        #input_A = input['A' if AtoB else 'B']
        #input_B = input['B' if AtoB else 'A']
        #print (input)
        input_A1=input#[0]
        input_A1=input_A1.view(-1,2,256,256)
        #print (input_A1.size())
        input_A11,input_A12=torch.split(input_A1, input_A1.size(1)//2, dim=1)
        #input_A_y=input[1]
        #input_B1=input[1]
        #input_B11,input_B12=torch.split(input_B1, input_B1.size(1)//2, dim=1)        
        #input_C1=input[2]
        #input_C11,input_C12=torch.split(input_C1, input_C1.size(0), dim=1)        
        #print (input_A11.size())
        #print (input_A12.size())
        #print (input_B11.size())
        #print (input_B12.size())        
        self.input_A.resize_(input_A11.size()).copy_(input_A11)
        #self.input_B.resize_(input_B11.size()).copy_(input_B11)
        #self.input_C.resize_(input_C11.size()).copy_(input_C11)

        self.input_A_y.resize_(input_A12.size()).copy_(input_A12)
        #self.input_B_y.resize_(input_B12.size()).copy_(input_B12)
        #self.input_C_y.resize_(input_C12.size()).copy_(input_C12)                
        self.image_paths = 'test'#input['A_paths' if AtoB else 'B_paths']
    
    def dice_loss_ori(self,input, target):
        smooth = 1.
        #print (input.size())
        #print (target.size())
        iflat = input.view(-1)
        tflat = target.view(-1)
        #print (iflat)
        #print (tflat)
        iflat=iflat.cuda()
        tflat=tflat.cuda()
        intersection = (iflat * tflat).sum()
        
        #print ('intersection is:',intersection)
        #print ('iflat is:',iflat.sum())
        #print ('tflat is:',tflat.sum())
        return 1 - ((2. * intersection + smooth)/(iflat.sum() + tflat.sum() + smooth))
        
    def forward(self):
        self.real_A = Variable(self.input_A)
        self.real_A_y=Variable(self.input_A_y)
        #print (self.real_A.size())
        #print (self.real_A_y.size())
        self.real_B = Variable(self.input_B)
        self.real_B_y = Variable(self.input_B_y)      
        #self.real_C = Variable(self.input_C)
        #self.real_C_y = Variable(self.input_C_y)            
    def test(self):
        real_A = Variable(self.input_A, volatile=True)
        fake_B = self.netG_A(real_A)
        self.rec_A = self.netG_B(fake_B).data
        self.fake_B = fake_B.data

        real_B = Variable(self.input_B, volatile=True)
        fake_A = self.netG_B(real_B)
        self.rec_B = self.netG_A(fake_A).data
        self.fake_A = fake_A.data

    def mse_loss(input, target):
        return torch.sum((input - target)^2) / input.data.nelement()
    
    def generate_Seg_A_feature(self,img):
        #features_1 = torch.nn.Sequential( *list(self.netSeg_A.children())[0:100])(self.real_A)
        #print (torch.nn.Sequential( *list(self.netSeg_A.children())[:-2])(self.real_A))
        #print (torch.nn.Sequential( *list(next(self.netSeg_A.children()).children())[:-2])(self.real_A))
        #print (torch.nn.Sequential( *list(next(next(self.netSeg_A.children()).children()).children())[:-2])(self.real_A))
        
        feature_A_1=torch.nn.Sequential( *list(next(self.netSeg_A.children()).children())[:-2])(img)
        feature_A_2=torch.nn.Sequential( *list(next(next(self.netSeg_A.children()).children()).children())[:-2])(img)
        return feature_A_1,feature_A_2

    def generate_Seg_B_feature(self,img):
        #features_1 = torch.nn.Sequential( *list(self.netSeg_A.children())[0:100])(self.real_A)
        #print (torch.nn.Sequential( *list(self.netSeg_A.children())[:-2])(self.real_A))
        #print (torch.nn.Sequential( *list(next(self.netSeg_A.children()).children())[:-2])(self.real_A))
        #print (torch.nn.Sequential( *list(next(next(self.netSeg_A.children()).children()).children())[:-2])(self.real_A))
        
        feature_B_1=torch.nn.Sequential( *list(next(self.netSeg_B.children()).children())[:-2])(img)
        feature_B_2=torch.nn.Sequential( *list(next(next(self.netSeg_B.children()).children()).children())[:-2])(img)
        return feature_B_1,feature_B_2


    def get_image_paths(self):
        return self.image_paths
    
    def cal_feature_loss(self,img_A,img_AB):
        
        if self.opt.use_MMD_feature==1:
            base = 1.0
            sigma_list = [1, 2, 4, 8, 16]
            sigma_list = [sigma / base for sigma in sigma_list]

            fa1,fa2=self.generate_Seg_A_feature(img_A)
            fb1,fb2=self.generate_Seg_B_feature(img_AB)        
            fa1=fa1.view(fa1.size(2),fa1.size(3))
            fa2=fa2.view(fa2.size(1),fa2.size(2),fa2.size(3))         
            fb1=fb1.view(fb1.size(2),fb1.size(3))
            fb2=fb2.view(fb2.size(1),fb2.size(2),fb2.size(3))                     

            #print (fa1)
            #print (fa2(1))
            #fa1=fa1.view(-1)
            #fa2=fa2.view(-1)
            #fb1=fb1.view(-1)
            #fb2=fb2.view(-1)

            mmd2_FD1 = mix_rbf_mmd2(fa1,fb1, sigma_list)
            #mmd2_FD2 = mix_rbf_mmd2(fa2,fb2, sigma_list)
            #print (fb2.data[0])
            mmd2_FD1 = F.relu(mmd2_FD1)
            #mmd2_FD2 = F.relu(mmd2_FD2)        
            mmd2_FD2=0

            for i in range (fb2.size(0)):
                fa2_tep=Variable(fa2.data[i])
                fb2_tep=Variable(fb2.data[i])
                mmd2_FD2_tep = mix_rbf_mmd2(fa2_tep,fb2_tep, sigma_list)
                mmd2_FD2_tep=F.relu(mmd2_FD2_tep)
                mmd2_FD2=mmd2_FD2+mmd2_FD2_tep
            
            feature_loss=self.opt.MMD_FeatureLambda*(mmd2_FD1+mmd2_FD2)
        else:

            fa1,fa2=self.generate_Seg_A_feature(img_A)
            fb1,fb2=self.generate_Seg_B_feature(img_AB)
            feature_loss1=torch.mean(torch.abs(fa1-fb1)*torch.abs(fa1-fb1))

            feature_loss2=torch.mean(torch.abs(fa2 - fb2)*torch.abs(fa2 - fb2))

            feature_loss=self.opt.FeatureLambda*(feature_loss1+feature_loss2)

        return feature_loss
    
    def cal_seg_loss (self,netSeg,pred,gt):
        self.pred,_,_=netSeg(pred)
        #print (self.pred.size())
        lmd=self.opt.SegLambda_B    
        seg_loss=lmd*self.dice_loss(self.pred,gt)
        #seg_loss=lmd*torch.nn.functional.binary_cross_entropy(self.pred,gt)
        return seg_loss

    def backward_Real_MRI_Seg(self,netSeg,img,gt):
        lmd=self.opt.SegLambda_B    
        seg_loss=self.cal_seg_loss(netSeg,img,gt)

        return seg_loss

    def backward_Seg(self,netSeg,img,gt,img_A,img_AB):
        
        # cal feature loss
        if self.opt.use_feature_loss == 1:
            feature_loss=self.cal_feature_loss(img_A,img_AB) # no need add seg stream in the arg
        else:
            feature_loss=0
                
        # cal seg loss
        #self.pred=netSeg(img)
        lmd=self.opt.SegLambda_B    
        seg_loss=self.cal_seg_loss(netSeg,img,gt)
        if self.opt.use_feature_loss  == 1 :
            total_loss=seg_loss+feature_loss
        else:
            total_loss=seg_loss
        #total_loss.backward()

        return seg_loss,feature_loss

    def backward_Seg_ct_conca_fmri(self,netSeg,img,gt,img_A,img_AB):
        
        # cal feature loss
        if self.opt.use_feature_loss == 1:
            feature_loss=self.cal_feature_loss(img_A,img_AB) # no need add seg stream in the arg
        else:
            feature_loss=0
                
        # cal seg loss
        #self.pred=netSeg(img)
        lmd=self.opt.SegLambda_B    
        seg_loss=self.cal_seg_loss(netSeg,img,gt)
        if self.opt.use_feature_loss  == 1 :
            total_loss=seg_loss+feature_loss
        else:
            total_loss=seg_loss
        #total_loss.backward()

        return seg_loss,feature_loss

    def backward_Seg_B_stream(self):
        gt_A=self.real_A_y # gt 
        img_AB=self.netG_A(self.real_A) # img_AB/fake_B
        img_mri=self.real_C
        img_mri_y=self.real_C_y
        seg_loss_AB,feature_loss_AB=self.backward_Seg(self.netSeg_B,img_AB,gt_A,self.real_A,img_AB)
        seg_loss_real_B=self.backward_Real_MRI_Seg(self.netSeg_B,img_mri,img_mri_y)        
        #if self.opt.use_feature_loss == 1:
        #    print ('segmentation loss in B:', seg_loss_AB.data[0]/self.opt.SegLambda_B, 'feature loss in B', feature_loss_AB.data[0]/self.opt.SegLambda_B)
        #else:
        #    print ('segmentation loss in B:', seg_loss_AB.data[0])
        #self.seg_loss_AB=seg_loss_AB.data[0]


    def backward_Seg_A_stream(self):
        gt_A=self.real_A_y # gt 
        img_A=self.real_A # gt
        img_AB=self.netG_A(self.real_A) # gt
        seg_loss_A,feature_loss_A=self.backward_Seg(self.netSeg_A,img_A,gt_A,self.real_A,img_AB)

        #if self.opt.use_feature_loss == 1:
        #    print ('segmentation loss in A:', seg_loss_A.data[0], 'feature loss in A', feature_loss_A.data[0])
        #else:
        #    print ('segmentation loss in A:', seg_loss_A.data[0])        
        
        #print (seg_loss_A.data[0])
        #self.seg_loss_A=seg_loss_A.data[0]

    
 

    def backward_Seg_A_and_B_stream(self):
        gt_A=self.real_A_y # gt 
        img_A=self.real_A # gt
        #img_AB=self.netG_A(self.real_A) # gt
        #img_A_AB=torch.cat((img_A,img_AB),1)

        img_mri=self.real_B
        img_mri_y=self.real_B_y

        #seg_loss_real_B=self.backward_Real_MRI_Seg(self.netSeg_B,img_mri,img_mri_y)        # Labeld_MRI_seg_constraint
        
        #print (img_A.size())
        #networks.print_network(self.netSeg_A)
        #d=self.netSeg_A(img_A)
        #print (d.size())
        #print (img_A.size())
        seg_loss_A,feature_loss_A=self.backward_Seg_ct_conca_fmri(self.netSeg_A,img_A,gt_A,self.real_A,img_A)  # CT_seg_constraint
        #seg_loss_AB,feature_loss_AB=self.backward_Seg(self.netSeg_B,img_AB,gt_A,self.real_A,img_AB)  # MRI_seg constraint
        #if self.opt.use_feature_loss == 1:
        #    print ('segmentation loss in A:', seg_loss_A.data[0], 'segmentation loss in B:', seg_loss_AB.data[0],'feature loss in A', feature_loss_A.data[0])
        #else:
        #    print ('segmentation loss in A:', seg_loss_A.data[0]/self.opt.SegLambda_B)        
        total_loss=seg_loss_A
        total_loss.backward()
        #print ('loss backwarded')
        tttp,_,_=self.netSeg_A(img_A)
        d0,d1,d2,d3,d4,d5,d6,d7,d8=self.cal_dice_loss(tttp,gt_A)
        #print (total_loss.data[0])
        #self.seg_loss_A=seg_loss_A.data[0]
        self.loss_seg=seg_loss_A.data[0]
        self.d0=d0.data[0]
        self.d1=d1.data[0]
        self.d2=d2.data[0]
        self.d3=d3.data[0]
        self.d4=d4.data[0]
        self.d5=d5.data[0]
        self.d6=d6.data[0]
        self.d7=0#d7.data[0]
        self.d8=0#d8.data[0]

    


    def backward_D_basic(self, netD, real, fake):
        # Real
        pred_real = netD(real)
        loss_D_real = self.criterionGAN(pred_real, True)
        # Fake
        pred_fake = netD(fake.detach())
        loss_D_fake = self.criterionGAN(pred_fake, False)
        # Combined loss
        loss_D = (loss_D_real + loss_D_fake) * 0.5
        # backward
        loss_D.backward()
        return loss_D

    def backward_D_A(self):
        fake_B = self.fake_B_pool.query(self.fake_B)
        loss_D_A = self.backward_D_basic(self.netD_A, self.real_B, fake_B)
        self.loss_D_A = loss_D_A.data[0]

    def backward_D_B(self):
        fake_A = self.fake_A_pool.query(self.fake_A)
        loss_D_B = self.backward_D_basic(self.netD_B, self.real_A, fake_A)
        self.loss_D_B = loss_D_B.data[0]

    def backward_G(self):
        lambda_idt = self.opt.identity
        lambda_A = self.opt.lambda_A
        lambda_B = self.opt.lambda_B
        # Identity loss
        if lambda_idt > 0:
            # G_A should be identity if real_B is fed.
            idt_A = self.netG_A(self.real_B)
            loss_idt_A = self.criterionIdt(idt_A, self.real_B) * lambda_B * lambda_idt
            # G_B should be identity if real_A is fed.
            idt_B = self.netG_B(self.real_A)
            loss_idt_B = self.criterionIdt(idt_B, self.real_A) * lambda_A * lambda_idt

            self.idt_A = idt_A.data
            self.idt_B = idt_B.data
            self.loss_idt_A = loss_idt_A.data[0]
            self.loss_idt_B = loss_idt_B.data[0]
        else:
            loss_idt_A = 0
            loss_idt_B = 0
            self.loss_idt_A = 0
            self.loss_idt_B = 0
     
        # GAN loss D_A(G_A(A))
        fake_B = self.netG_A(self.real_A)
        pred_fake = self.netD_A(fake_B)
        loss_G_A = self.criterionGAN(pred_fake, True)

        # GAN loss D_B(G_B(B))
        fake_A = self.netG_B(self.real_B)
        pred_fake = self.netD_B(fake_A)
        loss_G_B = self.criterionGAN(pred_fake, True)

        # Forward cycle loss
        rec_A = self.netG_B(fake_B)
        loss_cycle_A = self.criterionCycle(rec_A, self.real_A) * lambda_A

        # Backward cycle loss
        rec_B = self.netG_A(fake_A)
        loss_cycle_B = self.criterionCycle(rec_B, self.real_B) * lambda_B

        seg_loss_B=self.cal_seg_loss(self.netSeg_B,fake_B,self.real_A_y) # the seg_B_loss 

        #seg_loss_A=self.cal_seg_loss(self.netSeg_A,self.real_A,self.real_A_y) 
        real_a_tp=torch.cat((self.real_A,fake_B),1)
        seg_loss_A=self.cal_seg_loss(self.netSeg_A,real_a_tp,self.real_A_y)  # the seg_A_loss
        if self.opt.use_feature_loss == 1:
            feature_loss=self.cal_feature_loss(self.real_A,fake_B)
        else:
            feature_loss=0
        # combined loss
        
        #loss_G = loss_G_A + loss_G_B + loss_cycle_A + loss_cycle_B + loss_idt_A + loss_idt_B+seg_loss_B+seg_loss_A+feature_loss
        loss_G.backward()

        self.fake_B = fake_B.data
        #self.fake_B_variable=Variable(self.fake_B)
        self.fake_A = fake_A.data
        self.rec_A = rec_A.data
        self.rec_B = rec_B.data

        self.loss_G_A = loss_G_A.data[0]
        self.loss_G_B = loss_G_B.data[0]
        self.loss_cycle_A = loss_cycle_A.data[0]
        self.loss_cycle_B = loss_cycle_B.data[0]
        self.loss_seg_A=seg_loss_A.data[0]
        self.loss_seg_B=seg_loss_B.data[0]
        #self.loss_feature=feature_loss.data[0]

    def load_CT_seg_A(self, weight):
        self.load_network(self.netSeg_A,'Seg_A',weight)


    def optimize_parameters(self):
        # forward
        self.forward()

        # G_A and G_B
        #self.optimizer_G.zero_grad()
        #self.backward_G()
        #self.optimizer_G.step()
        # D_A
        #self.optimizer_D_A.zero_grad()
        #self.backward_D_A()
        #self.optimizer_D_A.step()
        # D_B
        #self.optimizer_D_B.zero_grad()
        #self.backward_D_B()
        #self.optimizer_D_B.step()
        
        self.optimizer_Seg_A.zero_grad()
        #self.optimizer_Seg_B.zero_grad()

        self.backward_Seg_A_and_B_stream()
        self.optimizer_Seg_A.step()
        #self.optimizer_Seg_B.step()



    def get_current_errors(self):
        #ret_errors = OrderedDict([('Seg_A',  self.loss_seg_A)])
        ret_errors = OrderedDict([('seg_loss', self.loss_seg),('d0', self.d0),('d1', self.d1),('d2', self.d2),('d3', self.d3),('d4', self.d4),('d5', self.d5),('d6', self.d6),('d7', self.d7),('d8', self.d8),])
        #if self.opt.identity > 0.0:
        #    ret_errors['idt_A'] = self.loss_idt_A
        #    ret_errors['idt_B'] = self.loss_idt_B
        return ret_errors

    def get_current_visuals(self):
        real_A = util.tensor2im(self.input_A)
        #fake_B = util.tensor2im(self.fake_B)
        #fake_B[fake_B>450]=450
        #rec_A = util.tensor2im(self.rec_A)
        #real_B = util.tensor2im(self.input_B)
        #fake_A = util.tensor2im(self.fake_A)
        #rec_B = util.tensor2im(self.rec_B)
        real_Ay=util.tensor2im_hd_neck(self.input_A_y)

        #real_A_AB_CT=torch.cat((self.real_A,self.fake_B),1)
        pred_A,_,rough=self.netSeg_A(self.input_A)
        pred_A=F.softmax(pred_A, dim=1)
        rough=F.softmax(rough, dim=1)                
        LP_refine=pred_A[0,1,:,:]
        LP_rough=rough[0,1,:,:]
        
        LP_rough=LP_rough.view(-1,1,256,256)
        LP_refine=LP_refine.view(-1,1,256,256)
        LP_rough=LP_rough.data
        LP_refine=LP_refine.data
        

        LP_rough,d999=self.tensor2im_jj(LP_rough)
        LP_refine,d999=self.tensor2im_jj(LP_refine)

        pred_A=torch.argmax(pred_A, dim=1)
        pred_A=pred_A.view(self.input_A.size()[0],1,256,256)
        pred_A=pred_A.data
        #global_map=global_map.data
        seg_A=util.tensor2im_hd_neck(pred_A) #
        #global_map=util.tensor2im(global_map)


        #pred_B=self.netSeg_B(self.real_B)
        #fake_B_seg=self.netSeg_B(self.fake_B)
        #pred_B=pred_B.data
        #fake_B_seg=fake_B_seg.data
        #seg_B=util.tensor2im(pred_B) #
        #fake_B_seg=util.tensor2im(fake_B_seg) #
        ret_visuals = OrderedDict([('real_A', real_A),('real_A_GT_seg',real_Ay),('real_A_seg', seg_A),('LP_rough', LP_rough),('LP_refine', LP_refine)])
        #if self.opt.isTrain and self.opt.identity > 0.0:
        #    ret_visuals['idt_A'] = util.tensor2im(self.idt_A)
        #    ret_visuals['idt_B'] = util.tensor2im(self.idt_B)
        return ret_visuals

    def get_current_seg(self):
        #tep=self.netSeg_A(self.input_A)
        #print (self.input_A)
        #print (self.pred)

        ret_visuals = OrderedDict([('d0', self.d0),('d1', self.d1),('d2', self.d2),('d3', self.d3),('d4', self.d4),('d5', self.d5),('d6', self.d6),('d0', self.d7),])
        return ret_visuals

    def save(self, label):
        #self.save_network(self.netG_A, 'G_A', label, self.gpu_ids)
        #self.save_network(self.netD_A, 'D_A', label, self.gpu_ids)
        #self.save_network(self.netG_B, 'G_B', label, self.gpu_ids)
        #self.save_network(self.netD_B, 'D_B', label, self.gpu_ids)
        self.save_network(self.netSeg_A, 'Seg_A', label, self.gpu_ids)
        #self.save_network(self.netSeg_B, 'Seg_B', label, self.gpu_ids)        
    
    def tensor2im_jj(self,image_tensor):
        #print (image_tensor)
        image_numpy = image_tensor[0].cpu().float().numpy()
        image_numpy_tep=image_numpy
        if image_numpy.shape[0] == 1:
            image_numpy = np.tile(image_numpy, (3, 1, 1))
        #image_numpy = (np.transpose(image_numpy, (1, 2, 0)) + 1) / 2.0 * 255.0

        self.test_A_tep = self.test_A[0].cpu().float().numpy()
        if self.test_A_tep.shape[0] == 1:
            self.test_A_tep = np.tile(self.test_A_tep, (3, 1, 1))

        image_numpy_all=np.concatenate((self.test_A_tep,image_numpy,),axis=2)
        #if np.min(image_numpy_all)<0:
        image_numpy_all = (np.transpose(image_numpy_all, (1, 2, 0)) + 1) / 2.0 * 255.0    
        #else:
        #    image_numpy_all = (np.transpose(image_numpy_all, (1, 2, 0)))*255.0                   
        

        return image_numpy_all.astype(np.uint8),image_numpy_tep

    def tensor2im_jj_3(self,image_tensor):
        image_numpy = image_tensor[0].cpu().float().numpy()
        image_numpy_tep=image_numpy
        if image_numpy.shape[0] == 1:
            image_numpy = np.tile(image_numpy, (3, 1, 1))
        #image_numpy = (np.transpose(image_numpy, (1, 2, 0)) + 1) / 2.0 * 255.0

        self.test_A_tep = self.test_A[0].cpu().float().numpy()
        if self.test_A_tep.shape[0] == 1:
            self.test_A_tep = np.tile(self.test_A_tep, (3, 1, 1))

        image_numpy_all=np.concatenate((self.test_A_tep,image_numpy,),axis=2)
        image_numpy_all = (np.transpose(image_numpy_all, (1, 2, 0)) + 1) / 2.0 * 255.0        
        

        return image_numpy_all.astype(np.uint8),image_numpy_tep