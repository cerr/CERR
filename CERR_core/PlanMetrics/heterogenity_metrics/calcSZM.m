function szmM = calcSZM(quantizedM, nL, szmType)
% function szmM = calcSZM(quantizedM, nL, szmType)
%
% This function calculates the Size-Zone matrix for the passed quantized
% image.
%
% INPUTS:
%       quantizedM: quantized 3d matrix obtained, for example, by
%       imquantize_cerr.m
%       nL: Number of gray levels.
%       szmType: flag, 1 or 2.
%                   1: 3D zones
%                   2: 2D zones
% OUTPUT:
%       szmM: size-zone matrix of size (nL x L)
%
% EXAMPLE:
%
% numRows = 10;
% numCols = 10;
% numSlcs = 1;
% 
% % number of gray levels
% nL = 3;
% 
% % create an image with random numbers
% imgM = randi(nL,numRows,numCols,numSlcs);
% 
% % set option to add run lengths from all directions
% szmType = 1;
% 
% % call the rlm calculator
% szmType = calcSZM(imgM, nL, szmType);
%
%
% APA, 03/30/2017

if szmType == 1
    numNeighbors = 26;
else
    numNeighbors = 8;
end

szmM = sparse(nL,numel(quantizedM));
maxSiz = 0;
for level = 1:nL
    connM = bwlabeln(quantizedM==level, numNeighbors);
    regiosSizV = accumarray(connM(connM > 0),1);
    if ~isempty(regiosSizV)
        maxSiz = max(maxSiz,max(regiosSizV));
    end
    szmM(level,:) = accumarray(regiosSizV,1,[size(szmM,2) 1])';
end
szmM = szmM(:,1:maxSiz);

