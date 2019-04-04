#!/usr/bin/env python

from __future__ import print_function
import SimpleITK as sitk
import numpy
import scipy
#import matplotlib
import matlab
#import matlab.engine
import six
from radiomics import getTestCase, featureextractor, imageoperations, firstorder
from radiomics.featureextractor import RadiomicsFeaturesExtractor


def extract(imagePath, maskPath, paramfilepath, preprocessingFilter, tempDir, dirStr):
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

    extractor = featureextractor.RadiomicsFeaturesExtractor(params)
    result = extractor.execute(imagePath, maskPath)
    sigmaValues = [3.0]
    for logImage, imageTypeName, inputKwargs in imageoperations.getLoGImage(image, mask, sigma=sigmaValues):
      #resultArray = sitk.GetArrayFromImage(logImage)
      #resultArray = matlab.double(resultArray.tolist())
      logImagePath = tempDir + imageTypeName + '.nrrd'
      try:
        sitk.WriteImage(logImage, logImagePath)
      except Exception as e:
        print("Couldn't write image to file (%s)." % e)

    #return resultArray

    extractor = featureextractor.RadiomicsFeaturesExtractor(params)

    result = extractor.execute(logImagePath, maskPath)
    for key, val in six.iteritems(result):
      strval = str(key)
      if strval.find("-") == -1:
        continue
      else:
        strval = strval.replace("-", "_")
        strval = strval.replace("-", "_")
        result[strval] = result.pop(key)
    return result

  elif preprocessingFilter == 'wavelet':
    resultdict = {}

    for decompositionImage, decompositionName, inputKwargs in imageoperations.getWaveletImage(image, mask):
      waveletName = 'wavelet-' + dirStr
      if decompositionName == waveletName:

        #resultArray = sitk.GetArrayFromImage(decompositionImage)
        #resultArray = matlab.double(resultArray.tolist())
        waveletImagePath = tempDir + decompositionName + '.nrrd'
        try:
          sitk.WriteImage(decompositionImage, waveletImagePath)
        except Exception as e:
          print("Couldn't write image to file (%s)." % e)


    #return resultArray
    extractor = featureextractor.RadiomicsFeaturesExtractor(params)

    result = extractor.execute(waveletImagePath, maskPath)
    for key, val in six.iteritems(result):
      strval = str(key)
      if strval.find("-") == -1:
        continue
      else:
        strval = strval.replace("-", "_")
        strval = strval.replace("-", "_")
        result[strval] = result.pop(key)
    return result

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
  result = extract(imagePath, maskPath, paramFilePath, 'LoG', 'C:\\Users\\pandyar1\\AppData\\Local\\Temp\\', '')


main()





