function log3M = recursiveLOG(img3M,sigma,PixelDimensions)
% function logY3M = recursiveLOG(img3M,sigma,PixelDimensions)
%
% APA, 6/18/2018

coeffS.sigma = sigma;

% y
% Derivative filter
derivativeOrder = 'second';
dim = 1;
coeffS.sigmad = coeffS.sigma / PixelDimensions(dim);
coeffS = setGaussOrder(coeffS,derivativeOrder);
logY3M = applyRecursGaussFilter(img3M,coeffS,dim);

% Smoothing filters
derivativeOrder = 'zero';
% x
dim = 2;
coeffS.sigmad = sigma / PixelDimensions(dim);
coeffS = setGaussOrder(coeffS,derivativeOrder);
logY3M = applyRecursGaussFilter(logY3M,coeffS,dim);
% z
dim = 3;
coeffS.sigmad = sigma / PixelDimensions(dim);
if coeffS.sigmad > 1
    coeffS = setGaussOrder(coeffS,derivativeOrder);
    logY3M = applyRecursGaussFilter(logY3M,coeffS,dim);
end


% x
% Derivative filter
derivativeOrder = 'second';
dim = 2;
coeffS.sigmad = coeffS.sigma / PixelDimensions(dim);
coeffS = setGaussOrder(coeffS,derivativeOrder);
logX3M = applyRecursGaussFilter(img3M,coeffS,dim);

% Smoothing filters
derivativeOrder = 'zero';
% y
dim = 1;
coeffS.sigmad = sigma / PixelDimensions(dim);
coeffS = setGaussOrder(coeffS,derivativeOrder);
logX3M = applyRecursGaussFilter(logX3M,coeffS,dim);
% z
dim = 3;
coeffS.sigmad = sigma / PixelDimensions(dim);
if coeffS.sigmad > 1
    coeffS = setGaussOrder(coeffS,derivativeOrder);
    logX3M = applyRecursGaussFilter(logX3M,coeffS,dim);
end

% log3M = logY3M + logX3M;

% z
% Derivative filter
derivativeOrder = 'second';
dim = 3;
coeffS.sigmad = coeffS.sigma / PixelDimensions(dim);
if coeffS.sigmad < 1
    log3M = logY3M + logX3M;
    return
end

coeffS = setGaussOrder(coeffS,derivativeOrder);
logZ3M = applyRecursGaussFilter(img3M,coeffS,dim);

% Smoothing filters
derivativeOrder = 'zero';
% x
dim = 2;
coeffS.sigmad = sigma / PixelDimensions(dim);
coeffS = setGaussOrder(coeffS,derivativeOrder);
logZ3M = applyRecursGaussFilter(logZ3M,coeffS,dim);
% y
dim = 1;
coeffS.sigmad = sigma / PixelDimensions(dim);
coeffS = setGaussOrder(coeffS,derivativeOrder);
logZ3M = applyRecursGaussFilter(logZ3M,coeffS,dim);

log3M = logY3M + logX3M + logZ3M;

