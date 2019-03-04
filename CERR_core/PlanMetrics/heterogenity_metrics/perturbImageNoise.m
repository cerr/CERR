function imgM = perturbImageNoise(imgM)
% function imgM = perturbImageNoise(imgM)
%
% Adds Gaussian noise to imgM. Standard deviation for Gaussian noise is
% estimated by getImageNoise.m
%
% APA, 2/25/2019

paramS.Direction.val = 'HH';
paramS.Wavelets.val = 'coif';
paramS.Index.val = '1';
outS = processImage('Wavelets',imgM,imgM.^0,paramS,NaN);
noiseStdDev = median(abs(outS.coif1_HH(:)))/0.6754;

imgClass = class(imgM);
sizV = size(imgM);
imgM = cast(double(imgM) + normrnd(0,noiseStdDev,sizV), imgClass);

