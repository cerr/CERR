function log3M = recursiveLOG(img3M,sigma,PixelSizeV)
% function log3M = recursiveLOG(img3M,sigma,PixelSizeV)
%
% INPUTS:
% img3M: 3d Image
% sigma: Gaussian smoothing width in physical units (mm).
% PixelSizeV: Physical size of the image pixel. 3-element vector containing
% sizes along y, x and z dimensions. It must be in mm in order to match
% DICOM/ITK.
%
% EXAMPLE:
% sigma = 3; %mm
% global planC
% indexS = planC{end};
% scanNum = 1;
% scan3M = single(planC{indexS.scan}(scanNum).scanArray) - ...
%     planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;
% dy = planC{indexS.scan}(scanNum).scanInfo(1).grid1Units;
% dx = planC{indexS.scan}(scanNum).scanInfo(1).grid2Units;
% dz = planC{indexS.scan}(scanNum).scanInfo(2).zValue - ...
%     planC{indexS.scan}(scanNum).scanInfo(1).zValue;
% dx = abs(dx);
% dy = abs(dy);
% dz = abs(dz);
% PixelSizeV = [dy, dx, dz]*10; % convert from cm to mm
% log3M = recursiveLOG(scan3M,sigma,PixelSizeV);
% 
% REFERENCES:
% 1. G Farnebäck, CF Westin, Improving Deriche-style recursive Gaussian filters,
% Journal of Mathematical Imaging and Vision, 26(3):293-299, December 2006?
% 2. https://itk.org/Doxygen/html/classitk_1_1LaplacianRecursiveGaussianImageFilter.html
%
% APA, 6/18/2018


% Pad
img3M = padarray(img3M,[4,4,4],'replicate','both');

coeffS.sigma = sigma;

% y
% Derivative filter
derivativeOrder = 'second';
dim = 1;
coeffS.sigmad = coeffS.sigma / PixelSizeV(dim);
coeffS = setGaussOrder(coeffS,derivativeOrder);
logY3M = applyRecursGaussFilter(img3M,coeffS,dim);

% Smoothing filters
derivativeOrder = 'zero';
% x
dim = 2;
coeffS.sigmad = sigma / PixelSizeV(dim);
coeffS = setGaussOrder(coeffS,derivativeOrder);
logY3M = applyRecursGaussFilter(logY3M,coeffS,dim);
% z
dim = 3;
coeffS.sigmad = sigma / PixelSizeV(dim);
coeffS = setGaussOrder(coeffS,derivativeOrder);
logY3M = applyRecursGaussFilter(logY3M,coeffS,dim);


% x
% Derivative filter
derivativeOrder = 'second';
dim = 2;
coeffS.sigmad = coeffS.sigma / PixelSizeV(dim);
coeffS = setGaussOrder(coeffS,derivativeOrder);
logX3M = applyRecursGaussFilter(img3M,coeffS,dim);

% Smoothing filters
derivativeOrder = 'zero';
% y
dim = 1;
coeffS.sigmad = sigma / PixelSizeV(dim);
coeffS = setGaussOrder(coeffS,derivativeOrder);
logX3M = applyRecursGaussFilter(logX3M,coeffS,dim);
% z
dim = 3;
coeffS.sigmad = sigma / PixelSizeV(dim);
coeffS = setGaussOrder(coeffS,derivativeOrder);
logX3M = applyRecursGaussFilter(logX3M,coeffS,dim);

% z
% Derivative filter
derivativeOrder = 'second';
dim = 3;
coeffS.sigmad = coeffS.sigma / PixelSizeV(dim);
coeffS = setGaussOrder(coeffS,derivativeOrder);
logZ3M = applyRecursGaussFilter(img3M,coeffS,dim);

% Smoothing filters
derivativeOrder = 'zero';
% x
dim = 2;
coeffS.sigmad = sigma / PixelSizeV(dim);
coeffS = setGaussOrder(coeffS,derivativeOrder);
logZ3M = applyRecursGaussFilter(logZ3M,coeffS,dim);
% y
dim = 1;
coeffS.sigmad = sigma / PixelSizeV(dim);
coeffS = setGaussOrder(coeffS,derivativeOrder);
logZ3M = applyRecursGaussFilter(logZ3M,coeffS,dim);

log3M = logY3M/PixelSizeV(1)^2 + logX3M/PixelSizeV(2)^2 + logZ3M/PixelSizeV(3)^2;

log3M = log3M(5:end-4,5:end-4,5:end-4);
