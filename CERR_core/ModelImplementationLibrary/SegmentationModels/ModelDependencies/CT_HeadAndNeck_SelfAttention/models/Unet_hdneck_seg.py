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


num_organ = 8  # put the organ number you used

class One_Hot(nn.Module):
    def __init__(self, depth):
        super(One_Hot, self).__init__()
        self.depth = depth
        self.ones = torch.eye(depth).cuda()

    def forward(self, X_in):
        n_dim = X_in.dim()
        output_size = X_in.size() + torch.Size([self.depth])
        num_element = X_in.numel()
        X_in = X_in.data.long().view(num_element)
        out = Variable(self.ones.index_select(0, X_in)).view(output_size)
        return out.permute(0, -1, *range(1, n_dim)).squeeze(dim=2).float()

    def __repr__(self):
        return self.__class__.__name__ + "({})".format(self.depth)



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





class unet_ct_seg_hdnk(BaseModel):
    def name(self):
        return 'unet_ct_seg_hdnk'

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
        self.num_organ=8    
        
        # usually unet
        self.netSeg_A=networks.get_Unet(1,self.num_organ+1,opt.init_type,self.gpu_ids)   

        self.criterion = nn.CrossEntropyLoss()

            

        if not self.isTrain or opt.continue_train:
            which_epoch = opt.which_epoch
            #self.load_network(self.netG_A, 'G_A', which_epoch)
            #self.load_network(self.netG_B, 'G_B', which_epoch)

            if self.isTrain:
                
                self.load_network(self.netSeg_A,'Seg_A',which_epoch)


        if self.isTrain:
            self.old_lr = opt.lr
            
            self.optimizer_Seg_A = torch.optim.Adam(self.netSeg_A.parameters(), lr=opt.lr, betas=(opt.beta1, 0.999),amsgrad=True)
            
            self.optimizers = []
            self.schedulers = []
            self.optimizers.append(self.optimizer_Seg_A)
          
            for optimizer in self.optimizers:
                self.schedulers.append(networks.get_scheduler(optimizer, opt))

        
    def set_test_input(self,input):
        input_A1=input[0]
        self.test_A,self.test_A_y=torch.split(input_A1, input_A1.size(0), dim=1)    
        #self.test_A=input_A1
        



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



        ##USE for CrossEntrophy
        
        #weights = [0.5, 1.0, 1.0, 1.0, 0.3, 1.0, 1.0, 1.0, 1.0]
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

        return loss


    def set_input(self, input):
        AtoB = self.opt.which_direction == 'AtoB'
        #input_A = input['A' if AtoB else 'B']
        #input_B = input['B' if AtoB else 'A']
        #print (input)
        input_A1=input[0]
        input_A1=input_A1.view(-1,2,256,256)

        input_A11,input_A12=torch.split(input_A1, input_A1.size(1)//2, dim=1)
  
        self.input_A.resize_(input_A11.size()).copy_(input_A11)


        self.input_A_y.resize_(input_A12.size()).copy_(input_A12)

            
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

        return dice_0,dice_1,dice_2,dice_3,dice_4,dice_5,dice_6,dice_7,dice_8





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
        A_AB_seg=self.netSeg_A(test_img)
        #A_AB_seg=F.softmax(A_AB_seg,dim=1)
        #loss=self.dice_loss(A_AB_seg,self.test_A_y)
        loss=0
        #print (A_AB_seg.size())

        A_AB_seg=F.softmax(A_AB_seg, dim=1)

        LP_map=A_AB_seg[:,1,:,:]
        RP_map=A_AB_seg[:,2,:,:]
        RP_map=RP_map.view(1,1,256,256)
        LP_map=LP_map.view(1,1,256,256)
        RP_map=RP_map.data
        LP_map=LP_map.data
        

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

        #test_AB,d2=self.tensor2im_jj(test_AB)
        A_AB_seg=util.tensor2im_hd_neck(A_AB_seg)
        A_y=util.tensor2im_hd_neck(A_y)

        test_A_data=test_A_data[:,256:512,:]

        #test_AB=test_AB[:,256:512,:]
        A_AB_seg=A_AB_seg#[:,256:512,:]
        A_y=A_y#[:,256:512,:]



        image_numpy_all=np.concatenate((test_A_data,A_y,),axis=1)
        #image_numpy_all=np.concatenate((image_numpy_all,A_y,),axis=1)        
        image_numpy_all=np.concatenate((image_numpy_all,A_AB_seg,),axis=1)
      
        return loss,self.test_A.cpu().float().numpy(),A_AB_seg_out.cpu().float().numpy(),A_y_out.cpu().float().numpy(),image_numpy_all
        
        #return tep_dice_loss,ori_img,seg,gt,image_numpy,d0,d1,d2,d3,d4,d5,d6,d7,d8



        
    def forward(self):
        self.real_A = Variable(self.input_A)
        self.real_A_y=Variable(self.input_A_y)
        #print (self.real_A.size())
        #print (self.real_A_y.size())
        self.real_B = Variable(self.input_B)
        self.real_B_y = Variable(self.input_B_y)      
        #self.real_C = Variable(self.input_C)
        #self.real_C_y = Variable(self.input_C_y)            


    def mse_loss(input, target):
        return torch.sum((input - target)^2) / input.data.nelement()
 

    
    def cal_seg_loss (self,netSeg,pred,gt):
        self.pred=netSeg(pred)
        #print (self.pred.size())
        lmd=self.opt.SegLambda_B    
        seg_loss=lmd*self.dice_loss(self.pred,gt)
       
        return seg_loss

    def backward_Real_MRI_Seg(self,netSeg,img,gt):
        lmd=self.opt.SegLambda_B    
        seg_loss=self.cal_seg_loss(netSeg,img,gt)

        return seg_loss



    def backward_Seg_ct_conca_fmri(self,netSeg,img,gt,img_A,img_AB):
        


        lmd=self.opt.SegLambda_B    
        seg_loss=self.cal_seg_loss(netSeg,img,gt)
        

        return seg_loss
 

    def backward_Seg_A_and_B_stream(self):
        gt_A=self.real_A_y # gt 
        img_A=self.real_A # gt


        total_loss=self.backward_Seg_ct_conca_fmri(self.netSeg_A,img_A,gt_A,self.real_A,img_A)  # CT_seg_constraint
 
        #total_loss=seg_loss_A
        total_loss.backward()
        tttp=self.netSeg_A(img_A)
        d0,d1,d2,d3,d4,d5,d6,d7,d8=self.cal_dice_loss(tttp,gt_A)
        #print (total_loss.data[0])
        #self.seg_loss_A=seg_loss_A.data[0]
        self.d0=d0.data[0]
        self.d1=d1.data[0]
        self.d2=d2.data[0]
        self.d3=d3.data[0]
        self.d4=d4.data[0]
        self.d5=d5.data[0]
        self.d6=d6.data[0]
        self.d7=d7.data[0]
        self.d8=d8.data[0]

    


    def load_CT_seg_A(self, weight):
        self.load_network(self.netSeg_A,'Seg_A',weight)


    def optimize_parameters(self):
        # forward
        self.forward()

        self.optimizer_Seg_A.zero_grad()
        #self.optimizer_Seg_B.zero_grad()

        self.backward_Seg_A_and_B_stream()
        self.optimizer_Seg_A.step()




    def get_current_errors(self): #ret_errors = OrderedDict([('Seg_A',  self.loss_seg_A)])
        ret_errors = OrderedDict([('d0', self.d0),('d1', self.d1),('d2', self.d2),('d3', self.d3),('d4', self.d4),('d5', self.d5),('d6', self.d6),('d7', self.d7),('d8', self.d8),])

        return ret_errors

    def get_current_visuals(self):
        real_A = util.tensor2im(self.input_A)
      
        real_Ay=util.tensor2im_hd_neck(self.input_A_y)

      
        pred_A=self.netSeg_A(self.input_A)
        pred_A=torch.argmax(pred_A, dim=1)
        pred_A=pred_A.view(self.input_A.size()[0],1,256,256)
        pred_A=pred_A.data
        seg_A=util.tensor2im_hd_neck(pred_A) #


        ret_visuals = OrderedDict([('real_A', real_A),('real_A_GT_seg',real_Ay),('real_A_seg', seg_A)])

        return ret_visuals

    def get_current_seg(self):


        ret_visuals = OrderedDict([('d0', self.d0),('d1', self.d1),('d2', self.d2),('d3', self.d3),('d4', self.d4),('d5', self.d5),('d6', self.d6),('d0', self.d7),])
        return ret_visuals

    def save(self, label):

        self.save_network(self.netSeg_A, 'Seg_A', label, self.gpu_ids)
      
    
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