% this script tests Laplacian of Gaussian pre-processing filter between CERR and pyradiomics.
% 
%
% RKP, 03/22/2018

% Random n x n x numofslices matrix
n = 50;
numofslices = 5;
testM = rand(n,n,numofslices);
maskBoundingBox3M = testM .^0;
scanType = 'LoG';
tmpDir = tempdir;
pyradLoGImgName = 'log-sigma-3-0-mm-3D.nrrd';

%% PyRadiomics LoG (FYI, Kernel Size = 3)
teststruct = PyradWrapper(testM, maskBoundingBox3M, scanType);
%pyradiomics log image 
pyrad_log_filename = fullfile(tmpDir, pyradLoGImgName);
[log3M, infoS] = nrrd_read(pyrad_log_filename);
%log3M = flipdim(data3M,3);

log3M = double(log3M);
log3M = permute(log3M, [2 1 3]);


%% CERR Recursive LOG filter
sigma = 3;
if exist('padarray.m','file')
    paddedImgM = padarray(testM,[4,4,4],0,'both');
else
    paddedImgM = padarray_oct(testM,[4,4,4],0,'both');
end
cerrLog3M = recursiveLOG(paddedImgM,sigma,infoS.PixelDimensions);
%cerrLog3M = recursiveLOG(testM,sigma,infoS.PixelDimensions);
cerrLog3M = cerrLog3M(5:end-4,5:end-4,5:end-4);



diff3M = (cerrLog3M - log3M)./(log3M+1e-5);
quantile99Diff = quantile(abs(diff3M(abs(log3M)>0.1)),0.99);
disp(['Percentage difference between CERR and Pyradiomics: ', num2str(quantile99Diff), '%'])

figure, 
slc = 3;
subplot(1,3,1), imagesc(testM(:,:,slc)), title('Original Image')
subplot(1,3,2), imagesc(cerrLog3M(:,:,slc)), title('CERR recursive LOG')
subplot(1,3,3), imagesc(log3M(:,:,slc)), title('ITK recursive LOG')

