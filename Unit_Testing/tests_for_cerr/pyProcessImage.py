#!/usr/bin/env python

from __future__ import print_function
import SimpleITK as sitk
import numpy
import scipy
import matlab
import six

import radiomics
from radiomics import imageoperations


def filtImg(imagePath, maskPath, filtName, paramS):
  """

  Wrapper function to apply image filters using pyradiomics.
  AI 06/11/2020

  """

  # Read image and mask
  print('Reading image and mask...')
  if imagePath is None or maskPath is None:  # Something went wrong, in this case PyRadiomics will also log an error
    print('Error reading input image and mask')
    exit()
 
  #Load and pre-process image and mask
  image = sitk.ReadImage(imagePath)
  mask = sitk.ReadImage(maskPath)

  #Apply filter
  if(filtName == "LoG"):

       sigma_mm = paramS['sigma']
       genOut = imageoperations.getLoGImage(image, mask, sigma=sigma_mm)

       logImgList = []
       for logImage, imageName, inputArgs in genOut:
         outImage = sitk.GetArrayFromImage(logImage)
         logImgList.append(outImage)

       return logImgList

  else: 
       return 0
   

def main():
 print('Loaded modules.')