
import torch
import torch.nn as nn
from torch.nn import init
import functools
from torch.autograd import Variable
from torch.optim import lr_scheduler
import numpy as np

from .unet_parts import *
import torch.nn.functional as F
from torchvision import models


        
def weights_init_normal(m):
    classname = m.__class__.__name__
    # print(classname)
    if classname.find('Conv') != -1:
        #print (m)
        init.normal_(m.weight.data, 0.0, 0.02)
    elif classname.find('Linear') != -1:
        init.normal(m.weight.data, 0.0, 0.02)
    elif classname.find('BatchNorm2d') != -1:
        init.normal(m.weight.data, 1.0, 0.02)
        init.constant(m.bias.data, 0.0)

def print_network(net):
    num_params = 0
    for param in net.parameters():
        num_params += param.numel()
    print(net)
    print('Total number of parameters: %d' % num_params)
    
def weights_init_xavier(m):
    classname = m.__class__.__name__
    # print(classname)
    if classname.find('Conv') != -1:
        init.xavier_normal(m.weight.data, gain=0.02)
    elif classname.find('Linear') != -1:
        init.xavier_normal(m.weight.data, gain=0.02)
    elif classname.find('BatchNorm2d') != -1:
        init.normal(m.weight.data, 1.0, 0.02)
        init.constant(m.bias.data, 0.0)

def get_Unet_Block_SA_inter_intra_wd_stride_kernel(n_channels,n_class,init_type='normal',gpu_ids=[],width=8,stride=2,kernel=3):
    net_Unet=None
    use_gpu = len(gpu_ids) > 0
    if use_gpu:
        assert(torch.cuda.is_available())
    net_Unet=UNet_block_SA_inter_intra_blockWidth_Stride_Kernel(n_channels=n_channels, n_classes=n_class,blockwidth=width,stride=stride,kernel_size=kernel)
    if use_gpu:
        net_Unet.cuda(gpu_ids[0])
    init_weights(net_Unet, init_type=init_type)

    return net_Unet

def get_Unet_Block_SA_inter_intra_wd_stride_kernel_second_layer(n_channels,n_class,init_type='normal',gpu_ids=[],width=8,stride=2,kernel=3):
    net_Unet=None
    use_gpu = len(gpu_ids) > 0
    if use_gpu:
        assert(torch.cuda.is_available())
    net_Unet=UNet_block_SA_inter_intra_blockWidth_Stride_Kernel_second_layer(n_channels=n_channels, n_classes=n_class,blockwidth=width,stride=stride,kernel_size=kernel)
    if use_gpu:
        net_Unet.cuda(gpu_ids[0])
    init_weights(net_Unet, init_type=init_type)

    return net_Unet



class UNet_block_SA_inter_intra_blockWidth_Stride_Kernel_second_layer(nn.Module):
    def __init__(self, n_channels, n_classes,blockwidth,stride,kernel_size):
        super(UNet_block_SA_inter_intra_blockWidth_Stride_Kernel_second_layer, self).__init__()
        self.inc = inconv(n_channels, 64)
        self.down1 = down(64, 128)
        self.down2 = down(128, 256)
        self.down3 = down(256, 512)
        self.down4 = down(512, 512)
        self.up1 = up(1024, 256)
        self.up2 = up(512, 128)
        self.up3 = up(256, 64)
        self.up4 = up(128, 64)
        self.outc = outconv(64, n_classes)
        self.nb_class=n_classes

        # PSA_net_attention
        in_channels=64
        reduced_channels=64
        fea_h=128
        fea_w=128
                                                       #64,8,2,3 ---->inter_intra
                                                       #64,8,2,2 ---->post_processing
        self.Block_SA1=Block_self_attention_inter_intra_change_second_layer(64,blockwidth,stride,kernel_size)  # (64,block_width=16,stride=2,kernel=3)
        self.Block_SA2=Block_self_attention_inter_intra_change_second_layer(64,blockwidth,stride,kernel_size)  # (64,block_width=16,stride=2,kernel=3)
        self.Block_SA3=Block_self_attention_inter_intra_change_second_layer(64,blockwidth,stride,kernel_size)  # (64,block_width=16,stride=2,kernel=3)

    def forward(self, x):
        x1 = self.inc(x)
        x2 = self.down1(x1)
        x3 = self.down2(x2)
        x4 = self.down3(x3)
        x5 = self.down4(x4)
        x = self.up1(x5, x4)
        x = self.up2(x, x3)
        x = self.up3(x, x2)

        x=self.Block_SA1(x)
        x=self.Block_SA2(x)
        #x=self.Block_SA3(x)        
        x = self.up4(x, x1)
        x = self.outc(x)

        return x,x,x



class UNet_block_SA_inter_intra_blockWidth_Stride_Kernel(nn.Module):
    def __init__(self, n_channels, n_classes,blockwidth,stride,kernel_size):
        super(UNet_block_SA_inter_intra_blockWidth_Stride_Kernel, self).__init__()
        self.inc = inconv(n_channels, 64)
        self.down1 = down(64, 128)
        self.down2 = down(128, 256)
        self.down3 = down(256, 512)
        self.down4 = down(512, 512)
        self.up1 = up(1024, 256)
        self.up2 = up(512, 128)
        self.up3 = up(256, 64)
        self.up4 = up(128, 64)
        self.outc = outconv(64, n_classes)
        self.nb_class=n_classes

        # PSA_net_attention
        in_channels=64
        reduced_channels=64
        fea_h=128
        fea_w=128
                                                       #64,8,2,3 ---->inter_intra
                                                       #64,8,2,2 ---->post_processing
        self.Block_SA1=Block_self_attention_inter_intra_change(64,blockwidth,stride,kernel_size)  # (64,block_width=16,stride=2,kernel=3)
        self.Block_SA2=Block_self_attention_inter_intra_change(64,blockwidth,stride,kernel_size)  # (64,block_width=16,stride=2,kernel=3)
        self.Block_SA3=Block_self_attention_inter_intra_change(64,blockwidth,stride,kernel_size)  # (64,block_width=16,stride=2,kernel=3)

    def forward(self, x):
        x1 = self.inc(x)
        x2 = self.down1(x1)
        x3 = self.down2(x2)
        x4 = self.down3(x3)
        x5 = self.down4(x4)
        x = self.up1(x5, x4)
        x = self.up2(x, x3)
        x = self.up3(x, x2)

        x = self.up4(x, x1)
        x=self.Block_SA1(x)
        x=self.Block_SA2(x)
        #x=self.Block_SA3(x)
        x = self.outc(x)

        return x,x,x



class Block_self_attention_inter_intra_change_second_layer(nn.Module):
    """ Position attention module"""
    #Ref from SAGAN
    def __init__(self, in_dim=64,block_width=16,stride=2,kernel=3):
        super(Block_self_attention_inter_intra_change_second_layer, self).__init__()
        self.chanel_in = in_dim

        self.block_width=block_width
        self.inter_block_SA=Position_AM_Module(64)
        self.softmax = nn.Softmax(dim=-1)
        
        self.block_num=128/self.block_width
        self.stride=stride
        self.kernel=kernel
        self.split_size_H=[]
        self.split_size_W=[]
        for k in range (int(self.block_num)):
            self.split_size_H.append(self.block_width)
            self.split_size_W.append(self.block_width)
        self.scane_x_max_num=128/(self.block_width*self.stride)
        self.scane_y_max_num=self.scane_x_max_num#256/(self.block_width*self.stride)

    def forward(self, x):

        #print (x.size())
        #m_batchsize, C, height, width = x.size()

        #splited_chunk_H=torch.split(x,self.split_size_H,2)
        #splited_chunk=[]
        #for splited_chunk_H_tp in splited_chunk_H:
        #    splited_chunk.append(torch.split(splited_chunk_H_tp,self.split_size_W,3))
        
        x_clone=x.clone()   
        #print ('x block number is ', self.scane_x_max_num)
        #print ('x block number is ', self.scane_y_max_num)
        for i in range(int(self.scane_x_max_num)+1):
            for j in range (int(self.scane_y_max_num)+1):
                #print ('i is ',i)
                #print ('j is ',j)
                start_x=i*self.block_width*self.stride
                
                end_x=i*self.block_width*self.stride+self.block_width*self.kernel
                start_y=j*self.block_width*self.stride
                end_y=j*self.block_width*self.stride+self.block_width*self.kernel


                #assert (start_x<256)
                #assert (start_y<256)
                #end_y=torch.min(end_y,256)
                #end_x=torch.min(end_x,256)
                if end_y>128:
                    end_y=128
                if end_x>128:
                    end_x=128

                #print ('start_x: ',start_x)
                #print ('end_x: ',end_x)
                #print ('start_y: ',start_y)
                #print ('end_y: ',end_y)

                if start_x<128 and start_y<128:
                    x_clone[:,:,start_x:end_x,start_y:end_y]=self.inter_block_SA(x[:,:,start_x:end_x,start_y:end_y])

        return x_clone


class Block_self_attention_inter_intra_change(nn.Module):
    """ Position attention module"""
    #Ref from SAGAN
    def __init__(self, in_dim=64,block_width=16,stride=2,kernel=3):
        super(Block_self_attention_inter_intra_change, self).__init__()
        self.chanel_in = in_dim

        self.block_width=block_width
        self.inter_block_SA=Position_AM_Module(64)
        self.softmax = nn.Softmax(dim=-1)
        
        self.block_num=256/self.block_width
        self.stride=stride
        self.kernel=kernel
        self.split_size_H=[]
        self.split_size_W=[]
        for k in range (int(self.block_num)):
            self.split_size_H.append(self.block_width)
            self.split_size_W.append(self.block_width)
        self.scane_x_max_num=256/(self.block_width*self.stride)
        self.scane_y_max_num=self.scane_x_max_num#256/(self.block_width*self.stride)

    def forward(self, x):

        #print (x.size())
        #m_batchsize, C, height, width = x.size()

        #splited_chunk_H=torch.split(x,self.split_size_H,2)
        #splited_chunk=[]
        #for splited_chunk_H_tp in splited_chunk_H:
        #    splited_chunk.append(torch.split(splited_chunk_H_tp,self.split_size_W,3))
        
        x_clone=x.clone()   
        #print ('x block number is ', self.scane_x_max_num)
        #print ('x block number is ', self.scane_y_max_num)
        for i in range(int(self.scane_x_max_num)+1):
            for j in range (int(self.scane_y_max_num)+1):
                #print ('i is ',i)
                #print ('j is ',j)
                start_x=i*self.block_width*self.stride
                
                end_x=i*self.block_width*self.stride+self.block_width*self.kernel
                start_y=j*self.block_width*self.stride
                end_y=j*self.block_width*self.stride+self.block_width*self.kernel


                #assert (start_x<256)
                #assert (start_y<256)
                #end_y=torch.min(end_y,256)
                #end_x=torch.min(end_x,256)
                if end_y>256:
                    end_y=256
                if end_x>256:
                    end_x=256

                #print ('start_x: ',start_x)
                #print ('end_x: ',end_x)
                #print ('start_y: ',start_y)
                #print ('end_y: ',end_y)

                if start_x<256 and start_y<256:
                    x_clone[:,:,start_x:end_x,start_y:end_y]=self.inter_block_SA(x[:,:,start_x:end_x,start_y:end_y])

        return x_clone



class Position_AM_Module(nn.Module):
    """ Position attention module"""
    #Ref from SAGAN
    def __init__(self, in_dim):
        super(Position_AM_Module, self).__init__()
        self.chanel_in = in_dim

        self.query_conv = nn.Conv2d(in_channels=in_dim, out_channels=in_dim, kernel_size=1)
        self.key_conv = nn.Conv2d(in_channels=in_dim, out_channels=in_dim, kernel_size=1)
        self.value_conv = nn.Conv2d(in_channels=in_dim, out_channels=in_dim, kernel_size=1)
        self.gamma = nn.Parameter(torch.zeros(1))

        self.softmax = nn.Softmax(dim=-1)
    def forward(self, x):
        """
            inputs :
                x : input feature maps( B X C X H X W)
            returns :
                out : attention value + input feature
                attention: B X (HxW) X (HxW)
        """
        m_batchsize, C, height, width = x.size()
        proj_query = self.query_conv(x).view(m_batchsize, -1, width*height).permute(0, 2, 1)
        proj_key = self.key_conv(x).view(m_batchsize, -1, width*height)
        energy = torch.bmm(proj_query, proj_key)
        attention = self.softmax(energy)
        proj_value = self.value_conv(x).view(m_batchsize, -1, width*height)

        out = torch.bmm(proj_value, attention.permute(0, 2, 1))
        out = out.view(m_batchsize, C, height, width)

        #out = self.gamma*out + x
        out = out + x
        return out


class UNet(nn.Module):
    def __init__(self, n_channels, n_classes):
        super(UNet, self).__init__()
        self.inc = inconv(n_channels, 64)
        self.down1 = down(64, 128)
        self.down2 = down(128, 256)
        self.down3 = down(256, 512)
        self.down4 = down(512, 512)
        self.up1 = up(1024, 256)
        self.up2 = up(512, 128)
        self.up3 = up(256, 64)
        self.up4 = up(128, 64)
        self.outc = outconv(64, n_classes)
        self.nb_class=n_classes

    def forward(self, x):
        x1 = self.inc(x)
        x2 = self.down1(x1)
        x3 = self.down2(x2)
        x4 = self.down3(x3)
        x5 = self.down4(x4)
        x = self.up1(x5, x4)
        x = self.up2(x, x3)
        x = self.up3(x, x2)
        x = self.up4(x, x1)
        x = self.outc(x)
        if self.nb_class==1:# use the sigmoid for dice loss
            x = F.sigmoid(x)
        return x


def weights_init_kaiming(m):
    classname = m.__class__.__name__
    # print(classname)
    if classname.find('Conv') != -1:
        init.kaiming_normal(m.weight.data, a=0, mode='fan_in')
    elif classname.find('Linear') != -1:
        init.kaiming_normal(m.weight.data, a=0, mode='fan_in')
    elif classname.find('BatchNorm2d') != -1:
        init.normal(m.weight.data, 1.0, 0.02)
        init.constant(m.bias.data, 0.0)


def weights_init_orthogonal(m):
    classname = m.__class__.__name__
    print(classname)
    if classname.find('Conv') != -1:
        init.orthogonal(m.weight.data, gain=1)
    elif classname.find('Linear') != -1:
        init.orthogonal(m.weight.data, gain=1)
    elif classname.find('BatchNorm2d') != -1:
        init.normal(m.weight.data, 1.0, 0.02)
        init.constant(m.bias.data, 0.0)


def get_Unet (n_channels,n_class,init_type='normal',gpu_ids=[]):
    net_Unet=None
    use_gpu = len(gpu_ids) > 0
    if use_gpu:
        assert(torch.cuda.is_available())
    net_Unet=UNet(n_channels=n_channels, n_classes=n_class)
    if use_gpu:
        net_Unet.cuda(gpu_ids[0])
    init_weights(net_Unet, init_type=init_type)

    return net_Unet

def init_weights(net, init_type='normal'):
    print('initialization method [%s]' % init_type)
    if init_type == 'normal':
        net.apply(weights_init_normal)
    elif init_type == 'xavier':
        net.apply(weights_init_xavier)
    elif init_type == 'kaiming':
        net.apply(weights_init_kaiming)
    elif init_type == 'orthogonal':
        net.apply(weights_init_orthogonal)
    else:
        raise NotImplementedError('initialization method [%s] is not implemented' % init_type)


def get_norm_layer(norm_type='instance'):
    if norm_type == 'batch':
        norm_layer = functools.partial(nn.BatchNorm2d, affine=True)
    elif norm_type == 'instance':
        norm_layer = functools.partial(nn.InstanceNorm2d, affine=False)
    elif norm_type == 'none':
        norm_layer = None
    else:
        raise NotImplementedError('normalization layer [%s] is not found' % norm_type)
    return norm_layer



def get_scheduler(optimizer, opt):
    if opt.lr_policy == 'lambda':
        def lambda_rule(epoch):
            lr_l = 1.0 - max(0, epoch + 1 + opt.epoch_count - opt.niter) / float(opt.niter_decay + 1)  #niter_decay_100 #niter 100
            return lr_l
        scheduler = lr_scheduler.LambdaLR(optimizer, lr_lambda=lambda_rule)
    elif opt.lr_policy == 'step':
        scheduler = lr_scheduler.StepLR(optimizer, step_size=opt.lr_decay_iters, gamma=0.5)
    elif opt.lr_policy == 'plateau':
        scheduler = lr_scheduler.ReduceLROnPlateau(optimizer, mode='min', factor=0.2, threshold=0.01, patience=5)
    else:
        return NotImplementedError('learning rate policy [%s] is not implemented', opt.lr_policy)
    return scheduler


