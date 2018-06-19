
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
subplot(1,3,1), imagesc(orig3M(:,:,13)), title('Original Image')
subplot(1,3,2), imagesc(cerrLog3M(:,:,13)), title('CERR recursive LOG')
subplot(1,3,3), imagesc(log3M(:,:,13)), title('ITK recursive LOG')


% Recursive Gaussian smoothing filter
coeffS.sigmad = sigma / infoS.PixelDimensions(1);
derivativeOrder = 'zero';
coeffS = setGaussOrder(coeffS,derivativeOrder);
cerrGauss3M = applyRecursGaussFilter(orig3M,coeffS,1);
figure, 
subplot(1,3,1), imagesc(orig3M(:,:,13)), title('Original Image')
subplot(1,3,2), imagesc(cerrGauss3M(:,:,13)), title('CERR recursive Gaussian')
subplot(1,3,3), imagesc(gauss3M(:,:,13)), title('ITK recursive Gaussian')

