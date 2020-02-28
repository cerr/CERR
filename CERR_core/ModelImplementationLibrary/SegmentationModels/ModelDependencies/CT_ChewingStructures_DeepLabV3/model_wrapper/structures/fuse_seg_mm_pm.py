# Author: Aditi Iyer
# Email: iyera@mskcc.org
# Date: Oct 25, 2019
# Description: Script to generate segmentations of masseters (left and right) and medial pterygoids (left and right)
#             by fusing results  from three different views.
# Architecture :  Deeplab v3+ with resnet backbone
# Usage: python fuse_seg_mm_pm.py [parameter_dictionary]
# Output: 2D masks saved as h5 files to output folder

import os
import time

import h5py
import numpy as np

from . import run_seg_mm_pm_ax
from . import run_seg_mm_pm_cor
from . import run_seg_mm_pm_sag


def main(argv):
    # Define paths
    inputH5Path = '/scratch/inputH5/'
    outputH5Path = '/scratch/outputH5/'

    inputH5PathAx = os.path.join(inputH5Path, 'axial')
    inputH5PathSag = os.path.join(inputH5Path, 'sagittal')
    inputH5PathCor = os.path.join(inputH5Path, 'coronal')

    # Get probability maps from different views
    t0 = time.time()
    probMapAx, fName = run_seg_mm_pm_ax.main(argv, inputH5PathAx)
    print(time.time() - t0)
    t1 = time.time()
    probMapSag = run_seg_mm_pm_sag.main(argv, inputH5PathSag)
    print(time.time() - t1)
    t2 = time.time()
    probMapCor = run_seg_mm_pm_cor.main(argv, inputH5PathCor)
    print(time.time() - t2)

    # Fuse maps
    avgProb = (probMapAx + probMapSag + probMapCor) / 3
    labels = np.argmax(avgProb, axis=0)

    # Write to HDF5
    print('writing output h5 files to disk')
    numSlc = labels.shape[2]
    path, file = os.path.split(fName)
    idx = file.find('_')
    prefix = file[0:idx]
    for iSlc in range(numSlc):
        maskfilename = prefix + '_slice_' + str(iSlc + 1) + '.h5'
        mask = labels[:, :, iSlc]
        with h5py.File(os.path.join(outputH5Path, maskfilename), 'w') as hf:
            hf.create_dataset("mask", data=mask)

    # print('Writing prob map...')
    # with h5py.File(os.path.join(outputH5Path, 'probMapAx.h5'), 'w') as hf:
    # hf.create_dataset("probAx", data=probMapAx)
    # with h5py.File(os.path.join(outputH5Path, 'probMapSag.h5'), 'w') as hf:
    # hf.create_dataset("probSag", data=probMapSag) #Same dim as ax
    # probMapSag = np.transpose(probMapSag,(0,3,1,2))
    # with h5py.File(os.path.join(outputH5Path, 'probMapCor.h5'), 'w') as hf:
    # hf.create_dataset("probCor", data=probMapCor) #Same dim as ax
    # probMapCor = np.transpose(probMapCor,(0,3,2,1))

    return labels
