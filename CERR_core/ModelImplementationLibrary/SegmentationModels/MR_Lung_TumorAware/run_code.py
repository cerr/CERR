#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Wed May 31 23:10:12 2017

@author: jiangj1
"""

#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Wed May 31 15:58:04 2017

@author: jiangj1
"""


#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Sun Apr 30 11:30:40 2017

@author: cc
"""
from keras.models import load_model
from keras.layers import merge
from keras.layers.core import Lambda
from keras.models import Model
from scipy import ndimage
import tensorflow as tf

from keras.models import Model
import tensorflow as tf
import scipy
# -*- coding: utf-8 -*-
from matplotlib import pyplot as plt
import os
import numpy as np
os.environ['KERAS_BACKEND'] = 'tensorflow'
#os.environ['THEANO_FLAGS'] = 'mode=FAST_RUN, device=gpu0, floatX=float32, optimizer=fast_compile'
from glob import glob
from keras import models
#from keras.models import Model
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
#os.environ['KERAS_BACKEND'] = 'theano'



print('-'*30)
#print('Loading saved weights...')
print('-'*30)

def normalize_data_MRI(data):
    #data[data<0]=24
    #data[data>1500]=1500
    data[data>667]=667
    #data=data-24
    
    #data=data*2./1500 - 1
    data=data*2./667 - 1
    #data=data*1./650
    return  (data)

      
    
img_w=256
img_h=256
import h5py    
import numpy as np    
test_data = h5py.File('img.h5','r')    
test_label=h5py.File('label.h5','r')   
for key in test_data.keys():
    print(key) #Names of the groups in HDF5 file.
	
test_data=test_data.get('SCAN')
test_label=test_label.get('SCAN')
test_data=np.array(test_data)
test_label=np.array(test_label)

print (test_data)
test_data=normalize_data_MRI(test_data)

# here you can put the images that you want to save
save_path=''#'/lila/data/deasy/Eric_Data/gan_related/trainsfer_learning_val_test/test_result_sv/'
save_path_pred=''#'/lila/data/deasy/Eric_Data/gan_related/trainsfer_learning_val_test/test_pred_result_sv/'

smooth=1


l=len(test_data)
with open('Unet_BN.json') as model_file: # change
  model3 = models.model_from_json(model_file.read())

model3.load_weights('weights.hdf5')
print ('finish tesing loading weight')


input_size=256
#model3.compile(loss=dice_coef_loss, optimizer=optimizer, metrics=[dice_coef])
test_data=test_data.reshape(len(test_data),input_size,input_size,1)
test_label=test_label.reshape(len(test_label),input_size,input_size,1)


dice_2d=0
for i in range(0,1):
#print ('test data image number is :', l)
#for i in range(5,6):

    gt=[]
    pre=[]
    for id in range(0,test_data.shape[0]):
        #print (id)
        #for id in range(0,l):
        #print ('id is ',id)
        aa=np.zeros((input_size,input_size))
        aa=test_data[id]
        #print(aa.shape)
        test=aa.reshape(1,input_size,input_size,1)
        
        #print ('-*30')
        #print ('loading weight and computing')
        #test=test+1024  # ############odaijini
        imgs_mask_test = model3.predict([test], verbose=0,batch_size=1)

        imgs_mask_test[imgs_mask_test>0.3]=1 # threshold to remove outliers
        imgs_mask_test[imgs_mask_test<=0.3]=0
        #print (np.max(imgs_mask_test))        
        ori_img=np.squeeze(test[0,:,:,:])
        ori_img=ori_img+1.0
        ori_img *= 255.0/ori_img.max()

        imgs_mask_test_save = np.squeeze(imgs_mask_test[0,:,:,:])
        imgs_mask_test_save1=255*imgs_mask_test_save        
        
        imgs_mask_test_apd=imgs_mask_test.reshape(input_size,input_size)
        bb=np.zeros((input_size,input_size))
        bb=test_label[id]
        img_color = np.zeros((input_size, input_size, 3), dtype=np.uint8)
        result_color=np.zeros((input_size, input_size, 3), dtype=np.uint8)
        pre_color=np.zeros((input_size, input_size, 3), dtype=np.uint8)
        img_color[:,:,0]=ori_img
        img_color[:,:,1]=ori_img
        img_color[:,:,2]=ori_img
        
        bb=bb.reshape(input_size,input_size)
        pre_color[:,:,1]=bb*255
        imgs_mask_test1=imgs_mask_test.reshape(input_size,input_size)
        result_color[:,:,0]=imgs_mask_test1*255
        
        img_color_img=Image.fromarray(img_color,'RGB')
        result_color_img=Image.fromarray(result_color,'RGB')
        pre_color_img=Image.fromarray(pre_color,'RGB')
        
        
        new_img1=Image.blend(img_color_img,result_color_img,0.2)
        new_img=Image.blend(new_img1,pre_color_img,0.2)
        save_name=save_path+str(i)+'_'+str(id)+'.png'
        new_img.save(save_name)
        #img_color_img.save(save_name)
     


