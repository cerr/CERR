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
cerrLog3M = recursiveLOG(padarray(testM,[4,4,4],0,'both'),sigma,infoS.PixelDimensions);
%cerrLog3M = recursiveLOG(testM,sigma,infoS.PixelDimensions);
cerrLog3M = cerrLog3M(5:end-4,5:end-4,5:end-4);



diff3M = (cerrLog3M - log3M)./(log3M+1e-5);
quantile99Diff = quantile(abs(diff3M(abs(log3M)>0.1)),0.99);
disp(['Percentage difference between CERR and ITK: ', num2str(quantile99Diff), '%'])

figure, 
slc = 3;
subplot(1,3,1), imagesc(testM(:,:,slc)), title('Original Image')
subplot(1,3,2), imagesc(cerrLog3M(:,:,slc)), title('CERR recursive LOG')
subplot(1,3,3), imagesc(log3M(:,:,slc)), title('ITK recursive LOG')


% 
% %% CERR LoG 
% %scanArray3M = flip(onesM,3);
% kernelSize = 5;
% sigmaVoxelV = [4 4 1]; %[0.79 0.79 6.5];
% filtScan3M = LoGFilt(testM,kernelSize,sigmaVoxelV);
% 
% %% Analysis and comparison between Pyradiomics and CERR
% maxMat = max(filtScan3M(:));
% maxPy = max(pyFiltM(:));
% diff3M = (filtScan3M/maxMat - pyFiltM/maxPy);
% quantile(abs(diff3M(:)),0.95)
% 
% figure('Name', 'diff3M'), imagesc(diff3M(:,:,13))
% 
% slcPyM = pyFiltM(:,:,5);
% slcMatM = filtScan3M(:,:,21);
% figure, imagesc(slcPyM), title('PyRad Gauss')
% figure, imagesc(slcMatM), title('CERR Gauss')
% 
% lap3M = -ones(3,3,3)/26;
% lap3M(2,2,2) = 1;
% lofFiltScan3M = convn(filtScan3M,lap3M);
% figure, imagesc(lofFiltScan3M(:,:,21)), title('CERR LOG')
% 
% lofPyrad3M = convn(pyFiltM,-lap3M);
% figure, imagesc(lofPyrad3M(:,:,5)), title('Pyrad LOG')
% 
% 
% %figure, imagesc(slcMatM/64.2026)
% figure('Name', 'slcPyM 13'), imagesc(slcPyM/1.6886e+03)
% figure('Name', 'slcMatM 13'), imagesc(flipud(slcMatM)/64.2026)
% diffM = slcPyM/1.6886e+03 - flipud(slcMatM)/64.2026;
% figure('Name', 'slc diff'), imagesc(diffM)
% 
% % figure, imagesc(slcMatM/64.2026)
% % figure, imagesc(slcPyM/1.6886e+03)
% % figure, imagesc(flipud(slcMatM)/64.2026)
% % figure, imagesc(slcPyM/1.6886e+03)
% % diffM = slcPyM/1.6886e+03 - flipud(slcMatM)/64.2026;
% % figure, imagesc(diffM)
% 
% 
% % 
% % %Matlab Gaussian fileter result:
% % matlabGaussian = imgaussfilt3(testM,4);
% % validM2 = matlabGaussian(6:end-6,6:end-6,6:end-6);
% % validM2./validPyM
% % 
% % %matlabGaussian./pydata 
% % gaussDiffV2 = (matlabGaussian - pydata) ./ matlabGaussian * 100
% % 
% % 
% % filename = 'C:\Users\pandyar1\AppData\Local\Temp\log-sigma-2-0-mm-3D.nrrd';
% % data3M = nrrdread(filename);
% % data3M = flipdim(data3M,3);
% % figure; imagesc(data3M(:,:,20))
% % figure; imagesc(filtScan3M(:,:,2))
% 
%     
