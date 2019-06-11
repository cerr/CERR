#Author: Rabia Haq 
#Email: haqr@mskcc.org
#Date: April 26, 2019
#Description: Script to segment cardio-pulmonary sub-structures from CT images
# model is trained using Deeplab v3+ using Resnet backbone
#Inputs: python run_seg_heart.py [path to folder containing input 3D h5 files] [path to folder where 3D masks are saved]
#Output: 3D masks saved as h5 files in specified folder (name preface MASK)

import sys
import os
import numpy as np
import h5py
import fnmatch
from modeling.sync_batchnorm.replicate import patch_replication_callback
from modeling.deeplab import *
from torchvision.utils import make_grid
from dataloaders.utils import decode_seg_map_sequence
from skimage.transform import resize
from dataloaders import custom_transforms as tr
from PIL import Image
from torchvision import transforms

input_size = 512

#function to look for h5 files in the given directory
def find(pattern, path):
    result = []
    for root, dirs, files in os.walk(path):
        for name in files:
            if fnmatch.fnmatch(name, pattern):
                result.append(os.path.join(root, name))
    return result


def main(argv):


    inputH5Path = '/scratch/inputH5/'
    outputH5Path = '/scratch/outputH5/'

    trainer = Trainer(argv)
    trainer.validation(inputH5Path, outputH5Path)


class Trainer(object):
    def __init__(self, argv):
        self.args = argv
        self.nclass = 10
        self.gpu_ids = [0]
        self.dataset = 'heart'
        #whether to use cuda (can be an additional argument i.e. sys.argv[3][5:])
        self.cuda = True 
        self.crop_size = 513

        #load model and weights here

        # Define network
        self.model = DeepLab(num_classes=self.nclass,
                        backbone='resnet',
                        output_stride=16,
                        sync_bn=False,
                        freeze_bn=False)

        model3 = torch.load('/software/heartModels/heart_ventricles_model.pth.tar') #requires nclass = 10
        if self.cuda:
            self.model = torch.nn.DataParallel(self.model, device_ids=self.gpu_ids)
            patch_replication_callback(self.model)
            self.model = self.model.cuda()
            self.model.module.load_state_dict(model3['state_dict'])
        else:
            self.model.load_state_dict(model3['state_dict'])
        print('finish tesing loading weight')

    def validation(self, inputH5Path, outputH5Path):    
        self.model.eval()

        #this looks for all the h5 files that contain "SCAN" in the provided input H5 directory
        keyword = 'SCAN'
        files = find(keyword + '*.h5', inputH5Path)

        #loop over the h5 files in the directory specified, run the prediction, and save the final 3d mask here
        for filename in files:

            hf = h5py.File(filename, 'r')
            im = hf['/scan'][:]
            image = np.array(im)
            image = image.reshape(im.shape).transpose()
            print('Loaded SCAN array...')

            height, width, length = np.shape(image)

            final_mask = np.zeros((height, width, length), dtype=np.uint8)

            print('start inference')

            for id in range(1, length):

                tempImg = np.zeros((height, width))
                tempImg = image[:,:,id]

                #resize all images to 512x512
                tempImg = resize(tempImg, (512,512), anti_aliasing = True)
                
                #normalize image from 0-255 (as original pre-trained images were RGB between 0-255)
                tempImg = (255*(tempImg - np.min(tempImg))/np.ptp(tempImg).astype(int)).astype(np.uint8)
               
                #concating the image for all three channels
                if tempImg.ndim != 3:
                    tempImg = np.dstack([tempImg, tempImg, tempImg])

                tempImg = Image.fromarray(tempImg.astype(np.uint8))

                # creating sample with empty label fr now R.H. 1st March 2019
                _target = Image.fromarray(np.zeros(shape=(512,512)))
                sample = {'image': tempImg, 'label': _target}

                #transforming and converting to tensor
                sample = self.transform_ts(sample)

                #infer tempImg
                tempImg, target = sample['image'], sample['label']
                if self.cuda:
                    tempImg = tempImg.cuda()
                with torch.no_grad():
                    # converting image to a 4D tensor
                    tempImg = tempImg.view(1,tempImg.size(0), tempImg.size(1), tempImg.size(2))
                    output = self.model(tempImg)
        
                #convert the image back into h5 and write to file
                out_image = torch.max(output[:3], 1)[1].detach().cpu().numpy()
                out_image = Image.fromarray(out_image[0,].astype(np.int16))
                final_mask[:, :, id] = np.array(out_image.resize((width, height), Image.NEAREST))
                
            #save the final 3d mask at the provided location
            path, file = os.path.split(filename)
            maskfilename = file.replace(keyword, 'MASK')

            #write result to h5 file
            with h5py.File(os.path.join(outputH5Path, maskfilename), 'w') as hf:
                hf.create_dataset("mask", data=final_mask)

    def transform_ts(self, sample):

        composed_transforms = transforms.Compose([
            tr.FixedResize(size=self.crop_size),
            tr.Normalize(mean=(0.316, 0.316, 0.316), std=(0.188, 0.188, 0.188)),
            tr.ToTensor()])

        return composed_transforms(sample)  


if __name__ == "__main__":
    main(sys.argv)