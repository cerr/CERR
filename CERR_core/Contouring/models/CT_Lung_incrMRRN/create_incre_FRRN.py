# -*- coding: utf-8 -*-

import os
import numpy as np
#os.environ['KERAS_BACKEND'] = 'theano'
#os.environ['THEANO_FLAGS'] = 'mode=FAST_RUN, device=gpu2, floatX=float32, optimizer=fast_compile'


from keras.models import Model
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
#K.set_image_dim_ordering('tf')
K.set_image_dim_ordering('th')
#os.environ['KERAS_BACKEND'] = 'theano'
#os.environ['THEANO_FLAGS'] = 'mode=FAST_RUN, device=gpu1, floatX=float32, optimizer=fast_compile'
img_w=160
img_h=160
smooth=1
###??dice_loss
def dice_coef(y_true, y_pred):
    #print((y_true).shape)
    y_true_f = K.flatten(y_true)
    y_pred_f = K.flatten(y_pred)
    intersection = K.sum(y_true_f * y_pred_f)

    return (2. * intersection + smooth) / (K.sum(y_true_f) + K.sum(y_pred_f) + smooth)


def dice_coef_loss(y_true, y_pred):
    return -dice_coef(y_true, y_pred)

def get_incr_FRRN():
    #inputs = Input((img_w,img_h,1))
    inputs = Input((1, img_w,img_h))

    
    conv1 = Convolution2D(48, 3, 3, border_mode='same')(inputs) #48
    conv1 = BatchNormalization()(conv1)
    conv1 = Activation('relu')(conv1)
    ###residual unit 1
    ru1 = Convolution2D(48, 3, 3, activation='relu', border_mode='same')(conv1) #48
    ru1 = Convolution2D(48, 3, 3, activation='relu', border_mode='same')(ru1)  #48
    ru1=merge([conv1, ru1], mode='sum', concat_axis=3)
    ru1=Activation('relu')(ru1)   
###residual unit 2
    ru2= Convolution2D(48, 3, 3, activation='relu', border_mode='same')(ru1) #48
    ru2 = Convolution2D(48, 3, 3, activation='relu', border_mode='same')(ru2) #48
    ru2=merge([ru1, ru2], mode='sum', concat_axis=3)
    ru2=Activation('relu')(ru2)   
 ###residual unit 3    
    ru3= Convolution2D(48, 3, 3, activation='relu', border_mode='same')(ru2) #48
    ru3 = Convolution2D(48, 3, 3, activation='relu', border_mode='same')(ru3) #48
    ru3=merge([ru2, ru3], mode='sum', concat_axis=3)
    ru3=Activation('relu')(ru3)       
    
    #pooling stream 1
    y1 =MaxPooling2D(pool_size=(2, 2))(ru3)
    #residual stream
    z1 =Convolution2D(32, 1, 1, activation='relu')(ru3)
    
    
    #FRRU 1
    frru1 =MaxPooling2D(pool_size=(2, 2))(z1)
    frru1=merge([frru1, y1], mode='concat', concat_axis=1)
    frru1 = Convolution2D(64, 3, 3, border_mode='same')(frru1)
    frru1 = BatchNormalization()(frru1)
    frru1 = Activation('relu')(frru1)    
    frru1 = Convolution2D(64, 3, 3, border_mode='same')(frru1)
    frru1 = BatchNormalization()(frru1)
    frru1 = Activation('relu')(frru1)         

    h1=Convolution2D(32, 1, 1, activation='relu')(frru1)
    h1=UpSampling2D(size=(2, 2))(h1)
 #########    
    z2 =merge([z1, h1], mode='sum', concat_axis=3)       
    y2=frru1
    
    #FRRU 2
    frru2 =MaxPooling2D(pool_size=(2, 2))(z2)
    frru2=merge([frru2, y2], mode='concat', concat_axis=1)
    frru2 = Convolution2D(64, 3, 3, border_mode='same')(frru2)
    frru2 = BatchNormalization()(frru2)
    frru2 = Activation('relu')(frru2)    
    frru2 = Convolution2D(64, 3, 3, border_mode='same')(frru2)
    frru2 = BatchNormalization()(frru2)
    frru2 = Activation('relu')(frru2)         
    h2=Convolution2D(32, 1, 1, activation='relu')(frru2)
    h2=UpSampling2D(size=(2, 2))(h2)
    
    z3 =merge([z2, h2], mode='sum', concat_axis=3)       
    y3=frru2
    # residual merge
    y3=merge([y3, frru1], mode='sum', concat_axis=3)  
    #FRRU 3
    frru3 =MaxPooling2D(pool_size=(2, 2))(z3)
    frru3=merge([frru3, y3], mode='concat', concat_axis=1)
    frru3 = Convolution2D(64, 3, 3, border_mode='same')(frru3)
    frru3 = BatchNormalization()(frru3)
    frru3 = Activation('relu')(frru3)    
    frru3 = Convolution2D(64, 3, 3, border_mode='same')(frru3)
    frru3 = BatchNormalization()(frru3)
    frru3 = Activation('relu')(frru3)         
    h3=Convolution2D(32, 1, 1, activation='relu')(frru3)
    h3=UpSampling2D(size=(2, 2))(h3)
    
    z4 =merge([z3, h3], mode='sum', concat_axis=3)       
    y4=frru3
    
    # resudial merge
    frru3_merge=merge([y3, frru3], mode='sum', concat_axis=3)  
    #pooling stream 2
    y4 =MaxPooling2D(pool_size=(2, 2))(y4)
    
    
     #FRRU 4
    frru4 =MaxPooling2D(pool_size=(4, 4))(z4)
    frru4=merge([frru4, y4], mode='concat', concat_axis=1)
    frru4 = Convolution2D(128, 3, 3, border_mode='same')(frru4)
    frru4 = BatchNormalization()(frru4)
    frru4 = Activation('relu')(frru4)    
    frru4 = Convolution2D(128, 3, 3, border_mode='same')(frru4)
    frru4 = BatchNormalization()(frru4)
    frru4 = Activation('relu')(frru4)         
    h4=Convolution2D(32, 1, 1, activation='relu')(frru4)
    h4=UpSampling2D(size=(4, 4))(h4)
    
    z5 =merge([z4, h4], mode='sum', concat_axis=3)       
    y5=frru4   
    
       #FRRU 5
    frru5 =MaxPooling2D(pool_size=(2, 2))(frru3_merge)
    frru5=merge([frru5, y5], mode='concat', concat_axis=1)
    frru5 = Convolution2D(128, 3, 3, border_mode='same')(frru5)
    frru5 = BatchNormalization()(frru5)
    frru5 = Activation('relu')(frru5)    
    frru5 = Convolution2D(128, 3, 3, border_mode='same')(frru5)
    frru5 = BatchNormalization()(frru5)
    frru5 = Activation('relu')(frru5)         
    h5=Convolution2D(64, 1, 1, activation='relu')(frru5)
    h5=UpSampling2D(size=(2, 2))(h5)
    
    z6 =merge([h5, frru3], mode='sum', concat_axis=3)       
    y6=frru5    

       #FRRU 6
    frru6 =MaxPooling2D(pool_size=(4, 4))(z5)
    frru6=merge([frru6, y6], mode='concat', concat_axis=1)
    frru6 = Convolution2D(128, 3, 3, border_mode='same')(frru6)
    frru6 = BatchNormalization()(frru6)
    frru6 = Activation('relu')(frru6)    
    frru6 = Convolution2D(128, 3, 3, border_mode='same')(frru6)
    frru6 = BatchNormalization()(frru6)
    frru6 = Activation('relu')(frru6)         
    h6=Convolution2D(32, 1, 1, activation='relu')(frru6)
    h6=UpSampling2D(size=(4, 4))(h6)
    
    z7 =merge([z5, h6], mode='sum', concat_axis=3)       
    y7=frru6  
    # resudlal merge
    frru6_merge =merge([frru6, y6], mode='sum', concat_axis=3)  
    
        
    
    # pooling #3 
    p7 =MaxPooling2D(pool_size=(2, 2))(y7)
    #FRRU 7
    
    frru7 =MaxPooling2D(pool_size=(8, 8))(z7)
    frru7=merge([frru7, p7], mode='concat', concat_axis=1)
    frru7 = Convolution2D(256, 3, 3, border_mode='same')(frru7)
    frru7 = BatchNormalization()(frru7)
    frru7 = Activation('relu')(frru7)    
    frru7 = Convolution2D(256, 3, 3, border_mode='same')(frru7)
    frru7 = BatchNormalization()(frru7)
    frru7 = Activation('relu')(frru7)         
    h7=Convolution2D(32, 1, 1, activation='relu')(frru7)
    h7=UpSampling2D(size=(8, 8))(h7)
    
    z8 =merge([z7, h7], mode='sum', concat_axis=3)       
    y8=frru7          
    
     #pooling stream 3
    #p8 =MaxPooling2D(pool_size=(2, 2))(y8)
    
    
     #FRRU 8
    frru8 =MaxPooling2D(pool_size=(2, 2))(frru6_merge)
    frru8=merge([frru8, y8], mode='concat', concat_axis=1)
    frru8 = Convolution2D(256, 3, 3, border_mode='same')(frru8)
    frru8 = BatchNormalization()(frru8)
    frru8 = Activation('relu')(frru8)    
    frru8 = Convolution2D(256, 3, 3, border_mode='same')(frru8)
    frru8 = BatchNormalization()(frru8)
    frru8 = Activation('relu')(frru8)         
    h8=Convolution2D(128, 1, 1, activation='relu')(frru8)
    h8=UpSampling2D(size=(2, 2))(h8)
    
    z9 =merge([frru6, h8], mode='sum', concat_axis=3)       
    y9=frru8   
    
       #FRRU 9
    frru9 =MaxPooling2D(pool_size=(4, 4))(frru3)
    frru9=merge([frru9, y9], mode='concat', concat_axis=1)
    frru9 = Convolution2D(256, 3, 3, border_mode='same')(frru9)
    frru9 = BatchNormalization()(frru9)
    frru9 = Activation('relu')(frru9)    
    frru9 = Convolution2D(256, 3, 3, border_mode='same')(frru9)
    frru9 = BatchNormalization()(frru9)
    frru9 = Activation('relu')(frru9)         
    h9=Convolution2D(64, 1, 1, activation='relu')(frru9)
    h9=UpSampling2D(size=(4, 4))(h9)
    
    z10 =merge([z6, h9], mode='sum', concat_axis=3)       
    y10=frru9   
    y10 =merge([y10, y8], mode='sum', concat_axis=3)    
       #pooling stream 4
    #p10 =MaxPooling2D(pool_size=(2, 2))(y10)
    
    
     #FRRU 10
    frru10 =MaxPooling2D(pool_size=(8, 8))(z8)
    frru10=merge([frru10, y10], mode='concat', concat_axis=1)
    frru10 = Convolution2D(256, 3, 3, border_mode='same')(frru10)
    frru10 = BatchNormalization()(frru10)
    frru10 = Activation('relu')(frru10)    
    frru10 = Convolution2D(256, 3, 3, border_mode='same')(frru10)
    frru10 = BatchNormalization()(frru10)
    frru10 = Activation('relu')(frru10)         
    h10=Convolution2D(32, 1, 1, activation='relu')(frru10)
    h10=UpSampling2D(size=(8, 8))(h10)
    
    z11 =merge([z8, h10], mode='sum', concat_axis=3)       
    y11=frru10  
    #residual merge
    frru10_merge =merge([frru10, y9], mode='sum', concat_axis=3) 
    # pooling 4
    p11=MaxPooling2D(pool_size=(2,2))(y11)
    
       #FRRU 11
    frru11 =MaxPooling2D(pool_size=(16,16))(z11)
    frru11=merge([frru11, p11], mode='concat', concat_axis=1)
    frru11 = Convolution2D(384, 3, 3, border_mode='same')(frru11)
    frru11 = BatchNormalization()(frru11)
    frru11 = Activation('relu')(frru11)    
    frru11 = Convolution2D(384, 3, 3, border_mode='same')(frru11)
    frru11 = BatchNormalization()(frru11)
    frru11 = Activation('relu')(frru11)         
    h11=Convolution2D(32, 1, 1, activation='relu')(frru11)
    h11=UpSampling2D(size=(16, 16))(h11)
    
    z12 =merge([z11, h11], mode='sum', concat_axis=3)       
    y12=frru11    
    
    
    ### unpooling 1
    #y12= UpSampling2D(size=(2, 2))(y12)
    
     #FRRU 12
    frru12 =MaxPooling2D(pool_size=(2, 2))(frru10_merge)
    frru12=merge([frru12, y12], mode='concat', concat_axis=1)
    frru12 = Convolution2D(384, 3, 3, border_mode='same')(frru12)
    frru12 = BatchNormalization()(frru12)
    frru12= Activation('relu')(frru12)    
    frru12 = Convolution2D(384, 3, 3, border_mode='same')(frru12)
    frru12 = BatchNormalization()(frru12)
    frru12 = Activation('relu')(frru12)         
    h12=Convolution2D(256, 1, 1, activation='relu')(frru12)
    h12=UpSampling2D(size=(2, 2))(h12)
    
    z13 =merge([frru10, h12], mode='sum', concat_axis=3)       
    y13=frru12   

     #FRRU 13
    frru13 =MaxPooling2D(pool_size=(4, 4))(z9)
    frru13=merge([frru13, y13], mode='concat', concat_axis=1)
    frru13 = Convolution2D(384, 3, 3, border_mode='same')(frru13)
    frru13 = BatchNormalization()(frru13)
    frru13= Activation('relu')(frru13)    
    frru13 = Convolution2D(384, 3, 3, border_mode='same')(frru13)
    frru13 = BatchNormalization()(frru13)
    frru13 = Activation('relu')(frru13)         
    h13=Convolution2D(128, 1, 1, activation='relu')(frru13)
    h13=UpSampling2D(size=(4, 4))(h13)
    
    z14 =merge([z9, h13], mode='sum', concat_axis=3)       
    y14=frru13    
    y14 =merge([y12, y14], mode='sum', concat_axis=3)    
     ### unpooling 2
    #y14= UpSampling2D(size=(2, 2))(y14)   
    
     #FRRU 14
    # residue merge y14 
    #y14_merge=merge([y14,])
    frru14 =MaxPooling2D(pool_size=(8, 8))(z10)
    frru14=merge([frru14, y14], mode='concat', concat_axis=1)
    frru14 = Convolution2D(384, 3, 3, border_mode='same')(frru14)
    frru14 = BatchNormalization()(frru14)
    frru14= Activation('relu')(frru14)    
    frru14 = Convolution2D(384, 3, 3, border_mode='same')(frru14)
    frru14 = BatchNormalization()(frru14)
    frru14 = Activation('relu')(frru14)         
    h14=Convolution2D(64, 1, 1, activation='relu')(frru14)
    h14=UpSampling2D(size=(8, 8))(h14)
    
    z15 =merge([z10, h14], mode='sum', concat_axis=3)       
    y15=frru14           
    
    
    
     #FRRU 15
    frru15 =MaxPooling2D(pool_size=(16, 16))(z12)
    frru15=merge([frru15, y15], mode='concat', concat_axis=1)
    frru15 = Convolution2D(384, 3, 3, border_mode='same')(frru15)
    frru15 = BatchNormalization()(frru15)
    frru15= Activation('relu')(frru15)    
    frru15 = Convolution2D(384, 3, 3, border_mode='same')(frru15)
    frru15 = BatchNormalization()(frru15)
    frru15 = Activation('relu')(frru15)         
    h15=Convolution2D(32, 1, 1, activation='relu')(frru15)
    h15=UpSampling2D(size=(16, 16))(h15)
    
    z16 =merge([z12, h15], mode='sum', concat_axis=3)       
    y16=frru15    
    y16 =merge([y16, y14], mode='sum', concat_axis=3)    
      ### unpooling 1
    up16= UpSampling2D(size=(2, 2))(y16)      
    
    
     #FRRU 16
    frru16 =MaxPooling2D(pool_size=(8, 8))(z16)
    frru16=merge([frru16, up16], mode='concat', concat_axis=1)
    frru16 = Convolution2D(256, 3, 3, border_mode='same')(frru16)
    frru16 = BatchNormalization()(frru16)
    frru16= Activation('relu')(frru16)    
    frru16 = Convolution2D(256, 3, 3, border_mode='same')(frru16)
    frru16 = BatchNormalization()(frru16)
    frru16 = Activation('relu')(frru16)         
    h16=Convolution2D(32, 1, 1, activation='relu')(frru16)
    h16=UpSampling2D(size=(8, 8))(h16)
    
    z17 =merge([z16, h16], mode='sum', concat_axis=3)       
    y17=frru16  
    

    
     #FRRU 17
    frru17 =MaxPooling2D(pool_size=(2, 2))(z14)
    frru17=merge([frru17, y17], mode='concat', concat_axis=1)
    frru17 = Convolution2D(256, 3, 3, border_mode='same')(frru17)
    frru17 = BatchNormalization()(frru17)
    frru17= Activation('relu')(frru17)    
    frru17 = Convolution2D(256, 3, 3, border_mode='same')(frru17)
    frru17 = BatchNormalization()(frru17)
    frru17 = Activation('relu')(frru17)         
    h17=Convolution2D(128, 1, 1, activation='relu')(frru17)
    h17=UpSampling2D(size=(2, 2))(h17)
    
    z18 =merge([z14, h17], mode='sum', concat_axis=3)       
    y18=frru17  
    
    #FRRU 18
    frru18 =MaxPooling2D(pool_size=(4, 4))(z15)
    frru18=merge([frru18, y18], mode='concat', concat_axis=1)
    frru18 = Convolution2D(256, 3, 3, border_mode='same')(frru18)
    frru18 = BatchNormalization()(frru18)
    frru18= Activation('relu')(frru18)    
    frru18 = Convolution2D(256, 3, 3, border_mode='same')(frru18)
    frru18 = BatchNormalization()(frru18)
    frru18 = Activation('relu')(frru18)         
    h18=Convolution2D(64, 1, 1, activation='relu')(frru18)
    h18=UpSampling2D(size=(4, 4))(h18)
    
    z19 =merge([z15, h18], mode='sum', concat_axis=3)       
    y19=frru18  
    y19 =merge([y19, y17], mode='sum', concat_axis=3)    
    # FRRU 19
    frru19 =MaxPooling2D(pool_size=(8, 8))(z17)
    frru19=merge([frru19, y19], mode='concat', concat_axis=1)
    frru19 = Convolution2D(256, 3, 3, border_mode='same')(frru19)
    frru19 = BatchNormalization()(frru19)
    frru19= Activation('relu')(frru19)    
    frru19 = Convolution2D(256, 3, 3, border_mode='same')(frru19)
    frru19 = BatchNormalization()(frru19)
    frru19 = Activation('relu')(frru19)         
    h19=Convolution2D(32, 1, 1, activation='relu')(frru19)
    h19=UpSampling2D(size=(8, 8))(h19)
    
    z20 =merge([z17, h19], mode='sum', concat_axis=3)       
    y20=frru19  
    
      ### unpooling 3
    up20= UpSampling2D(size=(2, 2))(y20)
    #FRRU 20
    frru20 =MaxPooling2D(pool_size=(4, 4))(z20)
    frru20=merge([frru20, up20], mode='concat', concat_axis=1)
    frru20 = Convolution2D(128, 3, 3, border_mode='same')(frru20)
    frru20 = BatchNormalization()(frru20)
    frru20= Activation('relu')(frru20)    
    frru20 = Convolution2D(128, 3, 3, border_mode='same')(frru20)
    frru20 = BatchNormalization()(frru20)
    frru20 = Activation('relu')(frru20)         
    h20=Convolution2D(32, 1, 1, activation='relu')(frru20)
    h20=UpSampling2D(size=(4, 4))(h20)
    
    z21 =merge([z20, h20], mode='sum', concat_axis=3)       
    y21=frru20  
    
    #FRRU 21
    frru21 =MaxPooling2D(pool_size=(2, 2))(z19)
    frru21=merge([frru21, y21], mode='concat', concat_axis=1)
    frru21 = Convolution2D(128, 3, 3, border_mode='same')(frru21)
    frru21 = BatchNormalization()(frru21)
    frru21= Activation('relu')(frru21)    
    frru21 = Convolution2D(128, 3, 3, border_mode='same')(frru21)
    frru21 = BatchNormalization()(frru21)
    frru21 = Activation('relu')(frru21)         
    h21=Convolution2D(64, 1, 1, activation='relu')(frru21)
    h21=UpSampling2D(size=(2, 2))(h21)
    
    z22 =merge([z19, h21], mode='sum', concat_axis=3)       
    y22=frru21  
    # residual merge
    y22_merge =merge([y22, z18], mode='sum', concat_axis=3) 
    #FRRU 22
    frru22 =MaxPooling2D(pool_size=(4, 4))(z21)
    frru22=merge([frru22, y22_merge], mode='concat', concat_axis=1)
    frru22 = Convolution2D(128, 3, 3, border_mode='same')(frru22)
    frru22 = BatchNormalization()(frru22)
    frru22= Activation('relu')(frru22)    
    frru22 = Convolution2D(128, 3, 3, border_mode='same')(frru22)
    frru22 = BatchNormalization()(frru22)
    frru22 = Activation('relu')(frru22)         
    h22=Convolution2D(32, 1, 1, activation='relu')(frru22)
    h22=UpSampling2D(size=(4, 4))(h22)
    
    z23 =merge([z21, h22], mode='sum', concat_axis=3)       
    y23=frru22  
    
    # uppooling
    
    up23=UpSampling2D(size=(2, 2))(y23)
    
    #FRRU 23
    frru23 =MaxPooling2D(pool_size=(2, 2))(z23)
    frru23=merge([frru23, up23], mode='concat', concat_axis=1)
    frru23 = Convolution2D(64, 3, 3, border_mode='same')(frru23)
    frru23 = BatchNormalization()(frru23)
    frru23= Activation('relu')(frru23)    
    frru23 = Convolution2D(64, 3, 3, border_mode='same')(frru23)
    frru23 = BatchNormalization()(frru23)
    frru23 = Activation('relu')(frru23)         
    h23=Convolution2D(32, 1, 1, activation='relu')(frru23)
    h23=UpSampling2D(size=(2, 2))(h23)
    
    z24 =merge([z23, h23], mode='sum', concat_axis=3)       
    y24=frru23  
    
        #FRRU 24
    frru24 =MaxPooling2D(pool_size=(2, 2))(z24)
    frru24=merge([frru24, y24], mode='concat', concat_axis=1)
    frru24 = Convolution2D(64, 3, 3, border_mode='same')(frru24)
    frru24 = BatchNormalization()(frru24)
    frru24= Activation('relu')(frru24)    
    frru24 = Convolution2D(64, 3, 3, border_mode='same')(frru24)
    frru24 = BatchNormalization()(frru24)
    frru24 = Activation('relu')(frru24)         
    h24=Convolution2D(32, 1, 1, activation='relu')(frru24)
    h24=UpSampling2D(size=(2, 2))(h24)
    
    z25 =merge([z24, h24], mode='sum', concat_axis=3)       
    y25=frru24  
    y25 =merge([y25, y24], mode='sum', concat_axis=3)    
    # FRRU 25
    
    frru25 =MaxPooling2D(pool_size=(2, 2))(z25)
    frru25=merge([frru25, y25], mode='concat', concat_axis=1)
    frru25 = Convolution2D(64, 3, 3, border_mode='same')(frru25)
    frru25 = BatchNormalization()(frru25)
    frru25= Activation('relu')(frru25)    
    frru25 = Convolution2D(64, 3, 3, border_mode='same')(frru25)
    frru25 = BatchNormalization()(frru25)
    frru25 = Activation('relu')(frru25)         
    h25=Convolution2D(32, 1, 1, activation='relu')(frru25)
    h25=UpSampling2D(size=(2, 2))(h25)
    
    z26 =merge([z25, h25], mode='sum', concat_axis=3)       
    y26=frru25  
    
    y27= UpSampling2D(size=(2, 2))(y26)   
    y28=merge([y27, z26], mode='concat', concat_axis=1)
    
    #y19=merge([y18, z18], mode='concat', concat_axis=3)
 
    y28 = Convolution2D(48, 5, 5, border_mode='same')(y28) #48
    y26 = BatchNormalization()(y28)
    y28 = Activation('relu')(y28)    
    
    ###residual unit 4
    ru4 = Convolution2D(48, 3, 3, activation='relu', border_mode='same')(y28) #48
    ru4 = Convolution2D(48, 3, 3, activation='relu', border_mode='same')(ru4) #48
    ru4=merge([y28, ru4], mode='sum', concat_axis=3)
    ru4=Activation('relu')(ru4)   
###residual unit 5
    ru5= Convolution2D(48, 3, 3, activation='relu', border_mode='same')(ru4) #48
    ru5 = Convolution2D(48, 3, 3, activation='relu', border_mode='same')(ru5) #48
    ru5=merge([ru4, ru5], mode='sum', concat_axis=3)
    ru5=Activation('relu')(ru5)   
 ###residual unit 6    
    ru6= Convolution2D(48, 3, 3, activation='relu', border_mode='same')(ru5) #48
    ru6 = Convolution2D(48, 3, 3, activation='relu', border_mode='same')(ru6) #48
    ru6=merge([ru5, ru6], mode='sum', concat_axis=3)
    ru6=Activation('relu')(ru6)          
     
     
     
     
     #residual stream   

    
    last = Convolution2D(1, 1, 1, activation='sigmoid')(ru6)
 
    model = Model(input=[inputs], output=[last])
    model.summary()
#
#    model.compile(optimizer=Adam(lr=1e-4), loss=['binary_crossentropy'], metrics=["accuracy"])

    return model

if __name__ == '__main__':
    from keras.utils.vis_utils import plot_model as plot
    model = get_FRRN()
    
    #with open('/lila/home/veerarah/data/endometrial/model_final-frrn_incremental_up_res_all_tf_256.json', 'w') as outfile: # save the model 
    #    outfile.write(json.dumps(json.loads(model.to_json()), indent=2))
#        
#    plot(model, 'FRRN.png', show_shapes=True)
#    print 'Compiled: OK'
#
#    # Train model or load weights
#    
#    train_data=np.load('train_data_new2.npy')
#    train_label=np.load('train_label_new2.npy')
#    
#    nb_epoch = 20
#    batch_size = 16
#    model_checkpoint = ModelCheckpoint('model_weight_ep20-lung-FRRN.hdf5', monitor='loss', save_best_only=True)
#    history = model.fit(train_data, train_label, batch_size=batch_size, nb_epoch=nb_epoch, validation_split=0.1,verbose=1,shuffle=True,callbacks=[model_checkpoint])
#
