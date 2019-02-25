function noiseStdDev = getImageNoise(imgM)
% function getImageNoise(imgM)
%
% This function returns the standard deviation of noise in passed image imgM.
%
% For every image voxel, random noise from a normal (Gaussian) distribution
% with mean 0 and standard deviation noiseStdDev can be generated. 
%
% References:
% 1. Zwanenburg A, Leger S, Agolli L, et al. Assessing robustness of radiomic 
% features by image perturbation. Sci Rep. 2019;9(1):614. 
% Published 2019 Jan 24. doi:10.1038/s41598-018-36938-4
% 2. Chang, S. G., Yu, B. & Vetterli, M. Adaptive wavelet thresholding for image denoising
% and compression. IEEE Transactions on Image Process. 9, 1532–1546 (2000). DOI
% 10.1109/83.862633.
% 3. Ikeda, M., Makino, R., Imai, K., Matsumoto, M. & Hitomi, R. A method for estimating
% noise variance of CT image. Comput. Med. Imaging Graph. 34, 642–650 (2010). DOI
% 10.1016/j.compmedimag.2010.07.005.
%
% APA, 2/25/2019

paramS.Direction.val = 'HH';
paramS.Wavelets.val = 'coif';
paramS.Index.val = '1';
outS = processImage('Wavelets',imgM,imgM.^0,paramS,NaN);
noiseStdDev = median(abs(outS.coif1_HH(:)))/0.6754;


