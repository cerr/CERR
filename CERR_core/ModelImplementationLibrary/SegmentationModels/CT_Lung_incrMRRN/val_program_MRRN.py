
import skimage
from scipy import ndimage
from keras.models import load_model
from keras.layers import merge
from keras.layers.core import Lambda
from keras.models import Model
from skimage.measure import regionprops
import tensorflow as tf

#from keras.models import Model
import tensorflow as tf
import scipy
# -*- coding: utf-8 -*-
#from matplotlib import pyplot as plt
import os
import numpy as np
os.environ['KERAS_BACKEND'] = 'tensorflow'
#os.environ['THEANO_FLAGS'] = 'mode=FAST_RUN, device=gpu0, floatX=float32, optimizer=fast_compile'
from glob import glob
from keras import models
from keras.layers.core import Activation, Reshape, Permute
from keras.layers.convolutional import Convolution2D, MaxPooling2D, UpSampling2D
from keras.layers.normalization import BatchNormalization
import json
from keras import backend as K
from keras.layers.core import Dense, Dropout, Activation, Flatten, Reshape
from keras.layers.merge import Add,Concatenate
from keras.callbacks import ModelCheckpoint
from keras.layers import Input, merge
from keras.optimizers import Adam
K.set_image_dim_ordering('tf')
from scipy.io import loadmat
from PIL import Image
#from Unet_mt_output import get_U_net_mt_output  
#from create_Unet import get_U_net

from create_incre_FRRN import get_incr_FRRN

#import csv

def main(argv):

    data_path =  sys.argv[1][5:]
    label_path = sys.argv[2][5:]
    save_path = sys.argv[3][5:]
    #csv_logger = open('/home/pandyar1/data/MRRN/results/DiceTestAccuraciesLog.csv', 'w')

    #writer = csv.DictWriter(csv_logger, fieldnames=['ID', 'Dice'])
    #writer.writeheader()

    print('-'*30)
    print('Loading saved weights...')
    print('-'*30)



    # load the npy tested data, the dcm file need to be converted to npy for reading
    ## change the path
    #test_data=np.load('/home/pandyar1/data/MRRN/data_Endometrial/CT_test_256.npy')
    test_data = np.load(data_path)
    # load the tested lable
    ## change the path
    #test_label=np.load('/home/pandyar1/data/MRRN/data_Endometrial/Expert_test_256.npy')
    test_label = np.load(label_path)
    # here put the path the result saved
    ## change the path
    #save_path='/lila/home/pandyar1/data/MRRN/results/'


    smooth=1


    print ('start testing loading weight')

    model3 = get_incr_FRRN() #get_U_net()
    print ('finish tesing loading weight:OK')
    # load the saved weights
    #model3.load_weights('/home/veerarah/data/pCA/unet_train_val_batch_18_50gb.hdf5')
    #model3.load_weights('/home/veerarah/data/pCA/model-boundaryDice/weights.85-0.59.hdf5')
    ## change the path
    model3.load_weights('/software/incremental_MRRN/weights.07--0.72.hdf5')
    print ('finish tesing loading weight')


    def dice_coef(y_true, y_pred):

        #y_true_f = tf.cast(K.flatten(y_true), tf.float32)

        #y_pred_f = tf.cast(K.flatten(y_pred), tf.float32)

        #intersection = K.sum(y_true_f * y_pred_f)

        #return (2. * intersection + smooth) / (K.sum(y_true_f) + K.sum(y_pred_f) + smooth)
        intersection = np.sum(y_true * y_pred)
        return (2. * intersection + smooth) / (np.sum(y_true) + np.sum(y_pred) + smooth)


    def dice_coef_loss(y_true, y_pred):
        return -dice_coef(y_true, y_pred)

    input_size=256 # as you want but must can be divided by 16 since 4 pooling
    csize = 160

    test_data=test_data.reshape(len(test_data),input_size,input_size,1)
    test_label=test_label.reshape(len(test_label),input_size,input_size,1)

    len_data=test_data.shape[0]

    print ('start inference')
    for id in range(0,len_data):

        aa=np.zeros((input_size,input_size))
        aa=test_data[id]
        b=aa.reshape(1,1, input_size,input_size)
        test=b[0, 0, 48:208,48:208]
        test = test.reshape(1, 1, csize, csize)
        res = model3.predict([test], verbose=0,batch_size=1)  # predict the label/segmentation, below code is just showing and saving
        imgs_mask_test = res[0]
        ori_img=np.squeeze(test[0,:,:,:])
        #print(ori_img.max())

        img_minmax = (ori_img - ori_img.min()) / (ori_img.max() - ori_img.min())
        ori_img = img_minmax * 255.0
        #ori_img *= 255.0/ori_img.max()


        bb=np.zeros((input_size,input_size))
        bb=test_label[id]

        ground=bb.reshape(1,1,input_size,input_size)
        #print(ground.shape)

        ground_save = np.squeeze(ground[0,:,48:208,48:208])
        #print(ground_save.shape)

        #print(imgs_mask_test.shape)

        dice = dice_coef(ground_save, imgs_mask_test.reshape(csize, csize))
        print(dice)

        #writer.writerow({'ID':id, 'Dice':dice})
        #csv_logger.flush()

        img_color = np.zeros((csize, csize, 3), dtype=np.uint8)
        result_color=np.zeros((csize, csize, 3), dtype=np.uint8)
        pre_color=np.zeros((csize, csize, 3), dtype=np.uint8)
        img_color[:,:,0]=ori_img
        img_color[:,:,1]=ori_img
        img_color[:,:,2]=ori_img

        bb=bb[48:208, 48:208].reshape(csize,csize)
        pre_color[:,:,1]=bb*255
        imgs_mask_test1=imgs_mask_test.reshape(csize,csize)
        result_color[:,:,0]=imgs_mask_test1*255

        img_color_img=Image.fromarray(img_color,'RGB')
        result_color_img=Image.fromarray(result_color,'RGB')
        pre_color_img=Image.fromarray(pre_color,'RGB')


        new_img1=Image.blend(img_color_img,result_color_img,0.2)
        new_img=Image.blend(new_img1,pre_color_img,0.2)
        save_name=save_path+str(id)+'.png'
        new_img.save(save_name)

    #csv_logger.close()

