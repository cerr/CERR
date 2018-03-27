#!/usr/bin/env python

from __future__ import print_function
import SimpleITK as sitk
import six
from radiomics import getTestCase, imageoperations, featureextractor, getTestCase
from radiomics.featureextractor import RadiomicsFeaturesExtractor


def extract(imagePath, maskPath, paramfilepath, *args):
  r"""
  RKP - 3/20/2018
  Wrapper class for calculation of a radiomics features using pyradiomics.

  """

  # testWaveletFilter = False
  # testLoGFilter = False

  image, mask = RadiomicsFeaturesExtractor().loadImage(imagePath, maskPath)

  if imagePath is None or maskPath is None:  # Something went wrong, in this case PyRadiomics will also log an error
    print('Error getting testcase!')
    exit()

  params = paramfilepath
  extractor = featureextractor.RadiomicsFeaturesExtractor(params)


  result = extractor.execute(imagePath, maskPath)
  for key, val in six.iteritems(result):
     strval = str(key)
     if strval.find("-") == -1:
       continue
     else:
       strval = strval.replace("-", "_")
       result[strval] = result.pop(key)


  if len(args) == 1 and args[0] == 'LoG':
    resultdict = {}
    for decompositionImage, decompositionName, inputKwargs in imageoperations.getLoGImage(image):
      resultArray = sitk.GetArrayFromImage(decompositionImage)
      # imgName = decompositionName + '.nrrd'
      # sitk.WriteImage(decompositionImage, imgName)
      resultdict[decompositionName] = resultArray
    return resultdict

  elif len(args) == 1 and args[0] == 'wavelet':
    resultdict = {}
    for decompositionImage, decompositionName, inputKwargs in imageoperations.getWaveletImage(image):
      resultArray=sitk.GetArrayFromImage(decompositionImage)
      # imgName = decompositionName+'.nrrd'
      # sitk.WriteImage(decompositionImage,imgName)
      resultdict[decompositionName] = resultArray
    return resultdict

  else:
    return result

#
# def main():
#
#   imagePath = 'C:\\Users\\pandyar1\\AppData\\Local\\Temp\\scan.nrrd'
#   maskPath = 'C:\\Users\\pandyar1\\AppData\\Local\\Temp\\mask.nrrd'
#   paramFilePath = 'W:\\Rutu\\CERR-testing\\Unit_Testing\\tests_for_cerr\pyradParams.yaml'
#   result = extract(imagePath, maskPath, paramFilePath)
#
#
# main()





