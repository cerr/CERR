import numpy as np
from PIL import Image
import h5py
import cv2
import time
import argparse
import sys
import os, fnmatch

import skimage
from scipy import ndimage
from keras.models import load_model
from keras.layers import merge
from keras.layers.core import Lambda
from keras.models import Model
from skimage.measure import regionprops
import tensorflow as tf

os.environ['KERAS_BACKEND'] = 'tensorflow'

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
from scipy.ndimage.interpolation import zoom


from create_incre_FRRN import get_incr_FRRN




#from keras.models import Model

import scipy
# -*- coding: utf-8 -*-
#from matplotlib import pyplot as plt

print("all imports done")
def find(pattern, path):
    result = []
    for root, dirs, files in os.walk(path):
        for name in files:
            if fnmatch.fnmatch(name, pattern):
                result.append(os.path.join(root, name))
    return result

input_size = 512  # as you want but can be divided by 16 since 4 pooling
print(input_size)
csize = 512
print(csize)

def main(argv):
    print("argv1")
    print(sys.argv[1])
    print("arg2")
    print(sys.argv[2])
    inputH5Path = sys.argv[1][5:]  # FLAGS.data_dir
    outputH5Path = sys.argv[2][5:]  # FLAGS.save_dir
    print("assignment of paths successful")
    print(inputH5Path)
    print(outputH5Path)

    keyword = 'SCAN'
    files = find(keyword + '*.h5', inputH5Path)
    print("files")
    print(files)
    print('start testing loading weight')

    model3 = get_incr_FRRN()

    with open(
            '/software/model_5l_lung-frrn_incremental_up_res_all_tf_drop_weight_residual_512.json') as model_file:
        model3 = models.model_from_json(model_file.read())
    print('weight test:OK')


    model3.load_weights('/software/weights.15--0.71.hdf5')
    print('finish tesing loading weight')



    for filename in files:
        print(filename)
        s = h5py.File(filename, 'r')
        original_scan = s['scan'][:]
        original_scan = np.flipud(np.rot90(original_scan, axes=(0, 2)))
        print('Loaded SCAN array...')
        path, file = os.path.split(filename)
        print(file.replace(keyword, 'MASK'))
        height, width, length = np.shape(original_scan)
        print("height,width,length")
        print(height)
        print(width)
        print(length)
        print("original scan shape")
        print(np.shape(original_scan))

        scan = original_scan
        print(np.shape(scan))
        scan = np.expand_dims(scan, 0)
        scan = np.moveaxis(scan, 3, 0)
        scan = np.moveaxis(scan, 1, 3)
        scan = scan.reshape(len(scan), 1, input_size, input_size)
        print("scan shape after processing")
        print(np.shape(scan))
        len_scan = scan.shape[0]

        final_mask = np.zeros((input_size, input_size, length), dtype=np.uint8)
        result_color = np.zeros((csize, csize, 3), dtype=np.uint8)
        print('start inference')

        for id in range(1, len_scan):
            print("id")
            print(id)
            aa = np.zeros((input_size, input_size))
            aa = scan[id]


            b = aa.reshape(1, input_size, input_size, 1)
            print("input shape")
            print(b.shape)


            res = model3.predict([b], verbose=0,
                                 batch_size=1)  # predict the label/segmentation, below code is just showing and saving
            imgs_mask_test = res[0]
            print("model prediction successful")

            print("result - imgs_mask_test.shape")
            print(imgs_mask_test.shape)

            imgs_mask_test1 = imgs_mask_test.reshape(csize, csize)
            result_color[:, :, 0] = imgs_mask_test1 * 255
            result_color_img = Image.fromarray(result_color, 'RGB')

            print(("image from array"))
            
            save_name = os.path.join("/lila/home/pandyar1/")+ str(id) + '.png'
            print(save_name)

            #result_color_img.save(save_name)

            print(save_name)

            imgs_mask_test1 = np.where(imgs_mask_test1 > 0.1, 1, 0)


            final_mask[:, :, id] = imgs_mask_test1
            print(np.max(imgs_mask_test1))
            print("final mask shape")
            print(final_mask.shape)
            print("final mask max")
            print(np.max(imgs_mask_test1))


        maskfilename = file.replace(keyword, 'MASK')
        with h5py.File(os.path.join(outputH5Path, maskfilename), 'w') as hf:
            hf.create_dataset("mask", data=final_mask)



if __name__ == "__main__":
    main(sys.argv)