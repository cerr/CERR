function cooccurM = calcCooccur(quantizedM, offsetsM, nL, cooccurType)
% function cooccurM = calcCooccur(quantizedM, offsetsM, nL, cooccurType)
%
% This function calculates the cooccurrence matrix for the passed quantized
% image.
%
% INPUTS:
%       quantizedM: quantized 3d matrix obtained, for example, by
%       imquantize_cerr.m
%       offsetsM: Offsets for directionality/neighbors, obtained by
%       getOffsets.m
%       nL: Number of gray levels.
%       cooccurType: flag, 1 or 2.
%                   1: returns a single cooccurrence matrix by combining
%                   contributions from all offsets into one cooccurrence
%                   matrix.
%                   2: returns cooccurM with each column containing 
%                   cooccurrence matrix for the row of offsetsM.
% OUTPUT:
%       cooccurM: cooccurrence matrix of size (nL*nL) x 1 for cooccurType =
%       1, or (nL*nL) x size(offsetsM,1) for cooccurType = 2.
%       cooccurM can be passed to cooccurToScalarFeatures.m to get texture
%       features.
%
%
% APA, 05/23/2016

% Default to building cooccurrence by combining all offsets
if ~exist('cooccurType','var')
    cooccurType = 1;
end

% Apply pading of 1 row/col/slc. This assumes offsets are 1. Need to
% parameterize this in case of offsets other than 2. Rarely used for
% medical images.
numColsPad = 1;
numRowsPad = 1;
numSlcsPad = 1;

% Get number of voxels per slice
[numRows, numCols, numSlices] = size(quantizedM);

% Pad quantizedM 
q = padarray(quantizedM,[numRowsPad numColsPad numSlcsPad],NaN,'both');

% Add level for NaN
lq = nL + 1;
q(isnan(q)) = lq;

q = uint16(q); % q is the quantized image

% Number of offsets
numOffsets = size(offsetsM,1);

% Indices of last level to filter out
nanIndV = false([lq*lq,1]);
nanIndV([lq:lq:lq*lq-lq, lq*lq-lq:lq*lq]) = true;

% Build linear indices column/row-wise for Symmetry
indRowV = zeros(1,lq*lq);
for i=1:lq
    indRowV((i-1)*lq+1:(i-1)*lq+lq) = i:lq:lq*lq;
end

tic
% Initialize cooccurrence matrix (vectorized for speed)
if cooccurType == 1
    cooccurM = zeros(lq*lq,1,'single');
else
    cooccurType = zeros(lq*lq,numOffsets,'single');
end
for off = 1:numOffsets
    
    offset = offsetsM(off,:);
    slc1M = q(numRowsPad+(1:numRows),numColsPad+(1:numCols),...
        numSlcsPad+(1:numSlices));
    slc2M = circshift(q,offset);
    slc2M = slc2M(numRowsPad+(1:numRows),numColsPad+(1:numCols),numSlcsPad+(1:numSlices))...
        + (slc1M-1)*lq;
    if cooccurType == 1
        cooccurM = cooccurM + accumarray(slc2M(:),1, [lq*lq,1]);
    else
        cooccurM(:,off) = accumarray(slc2M(:),1, [lq*lq,1]);
    end

end

cooccurM = cooccurM + cooccurM(indRowV,:); % for symmetry
cooccurM(nanIndV,:) = [];
cooccurM = bsxfun(@rdivide,cooccurM,sum(cooccurM,1)+eps);

return;

