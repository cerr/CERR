#!/usr/bin/env python

#from __future__ import print_function

import numpy
import SimpleITK as sitk
import radiomics
import scipy
import six
from radiomics import getTestCase, featureextractor, imageoperations, firstorder


# import matlab


def extract(imagePath, maskPath, paramfilepath, tempDir):
    """

    RKP - 3/20/2018
    Wrapper function for calculation of a radiomics features using pyradiomics.

    """

    # Read image and mask
    print('Reading image and mask...')
    if imagePath is None or maskPath is None:  # Something went wrong, in this case PyRadiomics will also log an error
        print('Error reading input image and mask')
        exit()
    else:
        print('image: ' + imagePath)
        print('mask: ' + maskPath)

    # Instantiate the extractor using the settings file
    print('Initializing feature extractor...')
    extractor = featureextractor.RadiomicsFeatureExtractor(paramfilepath)
    print('Done.')

    # Load and pre-process image and mask
    print('Loading images...')
    image, mask = extractor.loadImage(imagePath, maskPath)
    # image = sitk.ReadImage(imagePath)
    # mask = sitk.ReadImage(maskPath)

    # Calc features
    result = extractor.execute(image, mask)

    # Adjust fieldnames
    newResult = adjustKeyNames(result)
    return newResult


def adjustKeyNames(py_dict):
    """

    Replace hyphens with underscores in keys to produce valid matlab fieldnames 
    AI 6/10/2020

    """
    out_dict = py_dict.copy()
    for key, val in py_dict.items():
        strval = str(key)
        if strval.find("-") == -1:
            continue
        else:
            strval = strval.replace("-", "_")
            strval = strval.replace("-", "_")
            out_dict[strval] = out_dict.pop(key)
    return out_dict


def main():
    print('Loaded modules.')
