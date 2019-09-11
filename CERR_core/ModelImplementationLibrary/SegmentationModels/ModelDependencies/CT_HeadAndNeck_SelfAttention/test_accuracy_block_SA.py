import sys
import os
import h5py
import fnmatch
import numpy as np
import time
import torch.utils.data
import itertools
import scipy.io as sio


from data.data_loader import CreateDataLoader
from models.models import create_model
from util.visualizer import Visualizer
from util.util import save_image
from PIL import Image
from skimage.measure import regionprops


from options.train_options import TrainOptions
from imgaug import augmenters as iaa
import imgaug as ia
sometimes = lambda aug: iaa.Sometimes(0.5, aug)

opt = TrainOptions().parse()


#from pprint import pprint
def normalize_data(data):
    data[data<24]=24
    data[data>1524]=1524
    
    data=data-24
    
    data=data*2./1500 - 1
    #data=data*1./1500
    return  (data)
    #return  (data[0:15650,:])

def normalize_data_MRI_chuang(data):
    #data[data<0]=24
    data[data>1500]=1500
    #data[data>667]=667
    #data=data-24
    
    data=data*2./1500 - 1
    #data=data*2./667 - 1
    #data=data*1./650
    return  (data)
    
def normalize_data_MRI(data):
    #data[data<0]=24
    #data[data>1500]=1500
    data[data>667]=667
    #data=data-24
    
    #data=data*2./1500 - 1
    data=data*2./667 - 1
    #data=data*1./650
    return  (data)
    
def sample_CT(data):
    tep=[]
    for i in range (0,data.shape[0]/3-30):
        tep.append(data[i+3])
    tep=np.array(tep)
    
    return tep[0:tep.shape[0]-6,:]
    
def split_b_label (b_y,n):
    
    all_len_by=b_y.shape[0]
    start=0
    end= int(all_len_by*n)
    for i in range (0,end):

     b_y[i]=1
    return b_y

#function to look for h5 files in the given directory
def find(pattern, path):
    result = []
    for root, dirs, files in os.walk(path):
        for name in files:
            if fnmatch.fnmatch(name, pattern):
                result.append(os.path.join(root, name))
    return result
input_size = 256

def main(argv):
    print("main called")
    inputH5Path = '/scratch/inputH5/'
    outputH5Path = '/scratch/outputH5/'
    print("assignment of paths successful")
    print(inputH5Path)
    print(outputH5Path)

    model = create_model(opt)
    visualizer = Visualizer(opt)
    total_steps=0

    img_=[]
    gt_=[]

    keyword = 'SCAN'
    files = find(keyword + '*.h5', inputH5Path)
    print("files")
    print(files)

    for filename in files:
        print(filename)
        hf_data = h5py.File(filename, 'r')
        val_data_ct = hf_data.get('scan')
        val_data_ct = np.array(val_data_ct)

        val_data_ct = np.flipud(np.rot90(val_data_ct, axes=(0, 2)))
        print('Loaded SCAN array...')

        height, width, length = np.shape(val_data_ct)
        print("input scan shape")
        print(np.shape(val_data_ct))

        val_data_ct=normalize_data(val_data_ct)
        val_data_ct = val_data_ct.transpose(2, 1, 0)
        val_data_ct = val_data_ct.transpose(0, 2, 1)
        val_data_ct = val_data_ct.reshape(val_data_ct.shape[0], 1, val_data_ct.shape[1], val_data_ct.shape[2])

        #val_data_ct = val_data_ct.reshape(val_data_ct.shape[2], 1, val_data_ct.shape[0], val_data_ct.shape[1])
        print("val_data shape after reshaping")
        print(np.shape(val_data_ct))
        # originally added for comparison, make it zero, should work
        val_label_ct = np.zeros(shape=np.shape(val_data_ct))
        print("dummy label shape")
        print(np.shape(val_label_ct))


        images_ct_val=np.concatenate((np.array(val_data_ct), np.array(val_label_ct)), 1)

        print ('data set size is: ', val_data_ct.shape)
        print ('Finished data loading......')

        train_loader_c1=torch.utils.data.DataLoader(images_ct_val,#images_a_y_jj,  ## data + label
                                         batch_size=1,
                                         shuffle=False,
                                         num_workers=1)   


        path, file = os.path.split(filename)
        save_path = file.replace(keyword, 'MASK')

        # data_loader = CreateDataLoader(opt)
        # dataset = data_loader.load_data()
        # dataset_size = len(data_loader)
        # print('#training images = %d' % dataset_size)


        print ('start to loading the pre-trained CT segmentation')
        #model.load_CT_seg_A(opt.Load_CT_Weight_Seg_A)
        print ('finish loading the pre-trained CT segmentation')

        # second layer
        ##########################################################################
        #weight_read_path=dirpath+'model_save'
        weight_read_path = '/software/headAndNeckModels/model_save'
        print ('model location: ', weight_read_path)

        weight_=weight_read_path
        model.load_CT_seg_A(weight_)
        device= torch.device("cuda:0" if torch.cuda.is_available() else "cpu")
        ###########################################################################

        ###########################################################################
        final_mask = np.zeros((input_size, input_size, length), dtype=np.uint8)
        ###########################################################################


        with torch.no_grad(): # no grade calculation
            for i, (data_val) in enumerate(zip(train_loader_c1)):
                model.set_test_input(data_val)
                tep_dice_loss,ori_img,seg,gt,image_numpy=model.net_G_A_A2B_Segtest_image()
                #save_name=save_path+str(i)+'.png'
                #save_image(image_numpy, save_name)   # save the name in different images
                final_mask[:, :, i] = seg

        maskfilename = file.replace(keyword, 'MASK')
        with h5py.File(os.path.join(outputH5Path, maskfilename), 'w') as hf:
            hf.create_dataset("mask", data=final_mask)
    sys.exit()
if __name__ == "__main__":
    print("main will be called next")
    main(sys.argv)