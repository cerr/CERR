#!/usr/bin/env python

from __future__ import print_function
import SimpleITK as sitk
import numpy
import scipy
#import matplotlib
import matlab
#import matlab.engine
import six
from radiomics import getTestCase, imageoperations, featureextractor, getTestCase
from radiomics.featureextractor import RadiomicsFeaturesExtractor


def extract(imagePath, maskPath, paramfilepath, preprocessingFilter, tempDir):
  r"""
  RKP - 3/20/2018
  Wrapper class for calculation of a radiomics features using pyradiomics.

  """
  # reading original image directly
  #imageName, maskName = getTestCase('brain1')
  if imagePath is None or maskPath is None:  # Something went wrong, in this case PyRadiomics will also log an error
    print('Error getting test matrix!')
    exit()
  # image = sitk.ReadImage(imageName)
  # mask = sitk.ReadImage(maskName)

  image = sitk.ReadImage(imagePath)
  mask = sitk.ReadImage(maskPath)

  image, mask = RadiomicsFeaturesExtractor().loadImage(imagePath, maskPath)

  if imagePath is None or maskPath is None:  # Something went wrong, in this case PyRadiomics will also log an error
    exit()

  params = paramfilepath

#if wavelet or LoG specified in argument, return only the preprocessed image arrays
  if preprocessingFilter == 'LoG':
    resultdict = {}
    extractor = featureextractor.RadiomicsFeaturesExtractor(params)
    result = extractor.execute(imagePath, maskPath)
    sigmaValues = [3.0]
    for logImage, imageTypeName, inputKwargs in imageoperations.getLoGImage(image, sigma=sigmaValues):
      resultArray = sitk.GetArrayFromImage(logImage)
      resultArray = matlab.double(resultArray.tolist())
      imgName = tempDir + imageTypeName + '.nrrd'
      try:
        sitk.WriteImage(logImage, imgName)
      except Exception as e:
        print("Couldn't write image to file (%s)." % e)

      #resultdict[decompositionName] = resultArray
    return resultArray

  elif preprocessingFilter == 'wavelet':
    resultdict = {}
    for decompositionImage in imageoperations.getWaveletImage(image):
      resultArray=sitk.GetArrayFromImage(decompositionImage)
      # imgName = decompositionName+'.nrrd'
      # sitk.WriteImage(decompositionImage,imgName)
      resultArray = matlab.double(resultArray.tolist())
      resultdict[decompositionName] = resultArray
    for key, val in six.iteritems(resultdict):
      strval = str(key)
      if strval.find("-") == -1:
        continue
      else:
        strval = strval.replace("-", "_")
        strval = strval.replace("-", "_")
        resultdict[strval] = resultdict.pop(key)

    return resultdict
#perform feature extraction on original images and return the result
  else:    
    extractor = featureextractor.RadiomicsFeaturesExtractor(params)

    result = extractor.execute(imagePath, maskPath)
    for key, val in six.iteritems(result):
      strval = str(key)
      if strval.find("-") == -1:
        continue
      else:
        strval = strval.replace("-", "_")
        strval = strval.replace("-", "_")
        result[strval] = result.pop(key)
    return result

#
def main():

  imagePath = 'C:\\Users\\pandyar1\\AppData\\Local\\Temp\\scan.nrrd'
  maskPath = 'C:\\Users\\pandyar1\\AppData\\Local\\Temp\\mask.nrrd'
  paramFilePath = 'W:\\Rutu\\CERR-testing\\Unit_Testing\\tests_for_cerr\pyradParams.yaml'
  result = extract(imagePath, maskPath, paramFilePath, 'LoG', 'C:\\Users\\pandyar1\\AppData\\Local\\Temp\\')


main()





