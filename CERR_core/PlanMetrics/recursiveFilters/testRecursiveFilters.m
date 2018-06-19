
% Read images
[orig3M, infoS] = nrrd_read('M:\Rutu\Radiomics_TestSuite\Pyradiomics Filter Results\Original NRRD\brain1_image.nrrd');
orig3M = double(orig3M);

[gauss3M, infoS] = nrrd_read('M:\Rutu\Radiomics_TestSuite\Pyradiomics Filter Results\Recursive Gaussian\rg-sigma-3-0-mm-3D.nrrd');
gauss3M = double(gauss3M);

[log3M, infoS] = nrrd_read('M:\Rutu\Radiomics_TestSuite\Pyradiomics Filter Results\LoG\log-sigma-3-0-mm-3D.nrrd');
log3M = double(log3M);


% Recursive LOG filter
sigma = 3;
cerrLog3M = recursiveLOG(orig3M,sigma,infoS.PixelDimensions);

figure, 
slc = 13;
subplot(1,3,1), imagesc(orig3M(:,:,slc)), title('Original Image')
subplot(1,3,2), imagesc(cerrLog3M(:,:,slc)), title('CERR recursive LOG')
subplot(1,3,3), imagesc(log3M(:,:,slc)), title('ITK recursive LOG')


% Recursive Gaussian smoothing filter
derivativeOrder = 'zero';
sigma = 3;
% y
coeffS.sigmad = sigma / infoS.PixelDimensions(1);
coeffS = setGaussOrder(coeffS,derivativeOrder);
cerrGauss3M = applyRecursGaussFilter(orig3M,coeffS,1);
% x
coeffS.sigmad = sigma / infoS.PixelDimensions(2);
coeffS = setGaussOrder(coeffS,derivativeOrder);
cerrGauss3M = applyRecursGaussFilter(cerrGauss3M,coeffS,2);
% z
coeffS.sigmad = sigma / infoS.PixelDimensions(3);
coeffS = setGaussOrder(coeffS,derivativeOrder);
cerrGauss3M = applyRecursGaussFilter(cerrGauss3M,coeffS,3);

figure, 
subplot(1,3,1), imagesc(orig3M(:,:,slc)), title('Original Image')
subplot(1,3,2), imagesc(cerrGauss3M(:,:,slc)), title('CERR recursive Gaussian')
subplot(1,3,3), imagesc(gauss3M(:,:,slc)), title('ITK recursive Gaussian')

