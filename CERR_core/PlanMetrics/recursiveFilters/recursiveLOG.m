function log3M = recursiveLOG(img3M,sigma,PixelDimensions)
% function log3M = recursiveLOG(img3M,sigma,PixelDimensions)
%
% APA, 6/18/2018

coeffS.sigma = sigma;

% Derivative filter
% y
derivativeOrder = 'second';
dim = 1;
coeffS.sigmad = coeffS.sigma / PixelDimensions(dim);
coeffS = setGaussOrder(coeffS,derivativeOrder);
log3M = applyRecursGaussFilter(img3M,coeffS,dim);

% Smoothing filters
derivativeOrder = 'zero';
% x
dim = 2;
coeffS.sigmad = sigma / PixelDimensions(dim);
coeffS = setGaussOrder(coeffS,derivativeOrder);
log3M = applyRecursGaussFilter(log3M,coeffS,dim);
% z
dim = 3;
coeffS.sigmad = sigma / PixelDimensions(dim);
coeffS = setGaussOrder(coeffS,derivativeOrder);
log3M = applyRecursGaussFilter(log3M,coeffS,dim);

