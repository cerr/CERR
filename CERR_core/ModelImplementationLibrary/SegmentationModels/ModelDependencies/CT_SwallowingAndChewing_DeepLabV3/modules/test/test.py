# Test script for swallowing and chewing container to check that all imports are successful

import sys
import os
import numpy as np
import h5py
import fnmatch
from modeling.sync_batchnorm.replicate import patch_replication_callback
from modeling.deeplab import *
from skimage.transform import resize
from dataloaders import custom_transforms as tr
from PIL import Image
from torchvision import transforms

input_size = 320

def main(argv):
    print("All imports done. Test Successful")

if __name__ == "__main__":
    main(sys.argv)
