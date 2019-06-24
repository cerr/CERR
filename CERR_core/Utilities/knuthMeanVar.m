function [mu,varOut,numVals] = knuthMeanVar(val,newCalcFlag)
% function [mu,varOut] = knuthMeanVar(val,newCalcFlag)
%
% Knuth method for mean and standard deviation (like ITK)
%
% Input: value to add to the existing mean and variance calculation.
%
% Output: Mean and variance (var(xV,1))
%
% Example:
% newCalcFlag = true;
% knuthMeanVar([],true);
% valV = [1:10,100:105];
% for i = 1:length(valV)
%     [mu,varOut,numVals] = knuthMeanVar(valV(i));
% end
%
% To start a new calculation:
% newCalcFlag = true;
% knuthMeanVar([],newCalcFlag);
% valV = [1:5];
% for i = 1:length(valV)
%     [mu,varOut,numVals] = knuthMeanVar(valV(i));
% end
% 
% APA, 6/24/2019

if exist('newCalcFlag','var') && newCalcFlag
    clear persistent n
    clear persistent muPrev
    clear persistent varN
end

persistent n;
persistent muPrev;
persistent varN;

if isempty(val)
    numVals = n;
    mu = muPrev;
    varOut = varN/n;
    return;
end
if isempty(muPrev)
    muPrev = 0;
    varN = 0;
    n = 0;
end
n = n + 1;
mu = muPrev + (val - muPrev)/n;
varN = varN + (val-mu)*(val-muPrev);
muPrev = mu;
varOut = varN/n;
numVals = n;

