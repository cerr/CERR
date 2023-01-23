
% Read images
[orig3M, infoS] = nrrd_read('M:\Rutu\Radiomics_TestSuite\Pyradiomics Filter Results\Original NRRD\brain1_image.nrrd');
orig3M = double(orig3M);

[gauss3M, infoS] = nrrd_read('M:\Rutu\Radiomics_TestSuite\Pyradiomics Filter Results\Recursive Gaussian\rg-sigma-3-0-mm-3D.nrrd');
gauss3M = double(gauss3M);

[log3M, infoS] = nrrd_read('M:\Rutu\Radiomics_TestSuite\Pyradiomics Filter Results\LoG\log-sigma-3-0-mm-3D.nrrd');
log3M = double(log3M);


% Recursive LOG filter
sigma = 3;
if exist('padarray.m','file')
    paddedImgM = padarray(orig3M,[4,4,4],'replicate','both');
else
    paddedImgM = padarray_oct(orig3M,[4,4,4],'replicate','both');
end
cerrLog3M = recursiveLOG(paddedImgM,sigma,infoS.PixelDimensions);
cerrLog3M = cerrLog3M(5:end-4,5:end-4,5:end-4);
diff3M = (cerrLog3M - log3M)./(log3M+1e-5);
quantile99Diff = quantile(abs(diff3M(abs(log3M)>0.1)),0.99);
disp(['Percentage difference between CERR and ITK: ', num2str(quantile99Diff), '%'])

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

