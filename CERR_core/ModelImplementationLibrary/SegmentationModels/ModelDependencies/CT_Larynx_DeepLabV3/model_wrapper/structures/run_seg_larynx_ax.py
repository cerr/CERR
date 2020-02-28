# Author: Aditi Iyer
# Email: iyera@mskcc.org
# Date: Oct 10, 2019
# Description: Script to segment larynx from axial CT images
# Architecture :  Deeplab v3+ with resnet backbone
# Usage: python run_seg_larynx_ax.py [parameter_dictionary] [path to folder containing input 2D h5 files]
# Output: 3D probability map

import fnmatch
import os
import sys

import h5py
import numpy as np
from PIL import Image
from dataloaders import custom_transforms as tr
from modeling.deeplab import *
from modeling.sync_batchnorm.replicate import patch_replication_callback
from skimage.transform import resize
from torchvision import transforms

input_size = 320


# function to look for h5 files in the given directory
def find(pattern, path):
    result = []
    for root, dirs, files in os.walk(path):
        for name in files:
            if fnmatch.fnmatch(name, pattern):
                result.append(os.path.join(root, name))
    return result


def main(argv, inputH5Path):
    trainer = Trainer(argv)
    probMApAll, fname = trainer.validation(inputH5Path)
    return probMApAll, fname


class Trainer(object):
    def __init__(self, argv):
        self.args = argv
        self.nclass = 2
        self.gpu_ids = [0]
        self.cuda = True
        self.crop_size = 321

        # Define network
        self.model = DeepLab(num_classes=self.nclass,
                             backbone='resnet',
                             output_stride=16,
                             sync_bn=False,
                             freeze_bn=False)

        # Load model weights
        # modelDir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        # modelPath = os.path.join(modelDir, 'finalModels/Larynx_Ax_model.pth.tar')
        modelPath = '/software/models/Larynx_Ax_model.pth.tar'
        model = torch.load(modelPath)

        if self.cuda:
            self.model = torch.nn.DataParallel(self.model, device_ids=self.gpu_ids)
            patch_replication_callback(self.model)
            self.model = self.model.cuda()
            self.model.module.load_state_dict(model['state_dict'])
        else:
            self.model.load_state_dict(model['state_dict'])
        print('Loaded model weights')

    def validation(self, inputH5Path):
        self.model.eval()

        # Find H5 files in input dir
        files = find('*.h5', inputH5Path)
        files.sort(key=lambda f: int(''.join(filter(str.isdigit, f))))

        print('Computing probability maps (axial view)...')
        count = 0
        # loop over the h5 files in the directory specified, return predicted probability maps
        for filename in files:

            hf = h5py.File(filename, 'r')
            im = hf['/scan'][:]

            image = np.array(im)
            image = image.reshape(im.shape).transpose()
            height, width, nchannel = np.shape(image)

            # Initialize output array
            if count == 0:
                probMapAll = np.ones((self.nclass, height, width, len(files)))

            # Resize image
            tempImg = image
            tempImg = resize(tempImg, (input_size, input_size), anti_aliasing=True)

            # Normalize
            tempImg = (255 * (tempImg - np.min(tempImg)) / np.ptp(tempImg).astype(int)).astype(np.uint8)
            tempImg = Image.fromarray(tempImg.astype(np.uint8))

            # Create sample with empty label
            target = Image.fromarray(np.zeros((input_size, input_size)))
            sample = {'image': tempImg, 'label': target}

            # Transform sample
            sample = self.transform_ts(sample)

            # Segment image
            tempImg, target = sample['image'], sample['label']
            if self.cuda:
                tempImg = tempImg.cuda()
            with torch.no_grad():
                # converting image to a 4D tensor
                tempImg = tempImg.view(1, tempImg.size(0), tempImg.size(1), tempImg.size(2))
                output = self.model(tempImg)

            sm = torch.nn.Softmax(dim=1)
            prob = sm(output)

            # Get probability maps
            probMap = np.squeeze(prob.cpu().numpy())
            for c in range(0, self.nclass):
                classProbMap = probMap[c, :, :]
                resizProbMap = resize(classProbMap, (height, width), anti_aliasing=True)
                probMapAll[c, :, :, count] = resizProbMap

            count = count + 1

        print('Completed.')
        return probMapAll, filename

    def transform_ts(self, sample):

        composed_transforms = transforms.Compose([
            tr.FixedResize(size=self.crop_size),
            tr.Normalize(mean=(0.3416, 0.3416, 0.3416), std=(0.1889, 0.1889, 0.1889)),
            tr.ToTensor()])

        return composed_transforms(sample)


if __name__ == "__main__":
    main(sys.argv)
