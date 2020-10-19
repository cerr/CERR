# A Computational Environment for Radiological Research

## Features:

* Deep learning segmentation
* Radiomics
* User-friendly access to RT and Radiology meta-data
* Outcomes Modeling
* IMRTP
* Data Import
* Contouring

See https://cerr.github.io/CERR for more information

## Important bugs fixed
Date | Affected feature | Description | Hash
:---: | :---: | :---: | :---:
09/30/2020 | SUV calculation | Used type of Decay correction for SUV calculation. Used Series time for decay correction = "START". Note that Acquisition time was used irrespective of decay correction  | a9cb4fd
10/12/2020 | Rasterization | Fixed bug where structure segments on 1st and last row of image were not rasterized. | 95c4647
09/04/2019 | Radiomics features| Fixed bug where intensities outside the region of interest were included in discretization in case min/max were not specified. | 97f1c62
