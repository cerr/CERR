# A Computational Environment for Radiological Research

## Features:

* [Deep learning segmentation](https://github.com/cerr/CERR/wiki/Auto-Segmentation-models)
* [Radiomics](https://github.com/cerr/CERR/wiki/Radiomics)
* [User-friendly access to RT and Radiology meta-data](https://github.com/cerr/CERR/wiki/Data-Structure-(The-planC-object))
* [Outcomes Modeling](https://github.com/cerr/CERR/wiki/Radiotherapy-Outcomes-Explorer-(ROE))
* [IMRTP](https://github.com/cerr/CERR/wiki/IMRT-optimization-interfacing-with-an-external-solver)
* [Data Import](https://github.com/cerr/CERR/wiki/Importing-to-CERR)
* [Contouring](https://github.com/cerr/CERR/wiki/Contouring-tools)

See https://cerr.github.io/CERR for more information

## Important bugs fixed
Date | Affected feature | Description | Hash
:---: | :---: | :---: | :---:
02/25/2020 | Viewer | Fixed bug in opening the Viewer with Matlab2 2020b due to duplicate "matchs" function | aee266e
10/12/2020 | Rasterization | Fixed bug where structure segments on 1st and last row of image were not rasterized. | 95c4647
09/30/2020 | SUV calculation | Used type of Decay correction for SUV calculation. Used Series time for decay correction = "START". Note that Acquisition time was used irrespective of decay correction  | a9cb4fd
09/04/2019 | Radiomics features| Fixed bug where intensities outside the region of interest were included in discretization in case min/max were not specified. | 97f1c62
