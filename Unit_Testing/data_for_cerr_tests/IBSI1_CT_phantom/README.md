IBSI-1 CT radiomics phantom
===

This phantom was designed to test the image processing worklow and computation of image biomarkers. For details on use,
please consult the IBSI reference manual.

The phantom is available in both DICOM and NIfTI formats, and consists of the image itself (image) and its segmentation (mask).
The segmentation in DICOM format is an RTSTRUCT and needs to be converted to a voxel mask, whereas in the NIfTI format, the mask is already a voxel mask.
Consider using the NIfTI mask in case conversion of in-plane polygons to a mask is not supported.

## License
The phantom is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported Licence. To view a copy of this license, visit https://creativecommons.org/licenses/by-nc/3.0/ or send a letter to Creative Commons, PO Box 1866, Mount View, CA 94042, USA.

## Acknowledgments
The phantom was contributed by Philippe Lambin and published by CancerData (http://dx.doi.org/10.17195/candat.2016.08.1).
Alex Zwanenburg converted the phantom from DICOM and RTSTRUCT formats to NIfTI format.

## Citation information
Please cite the following when using this phantom:
* Lambin P, Leijenaar RT, Deist TM, Peerlings J, de Jong EE, van Timmeren J, Sanduleanu S, Larue RT, Even AJ, Jochems A, van Wijk Y. Radiomics: the bridge between medical imaging and personalized medicine. Nature Reviews Clinical Oncology. 2017 Dec;14(12):749.
* Lambin P. Radiomics Digital Phantom, CancerData (2016), DOI:10.17195/candat.2016.08.1