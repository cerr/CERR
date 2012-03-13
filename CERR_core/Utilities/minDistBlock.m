function minD = minDistBlock(v1, v2, blockSize);
%"minDistBlock"
%   Returns the minimum distance between two sets of points in n-D space.
%   Points are specified as a matrix size nPts x nDims, ie for 10 points in
%   3 dimensions, 10x3.
%
%   minDistBlock uses block processing to avoid out of memory errors.  A
%   blockSize parameter can be passed in, but if it does not exist the
%   default value of 5E6 is used.
%
% PEL 04/22/05
%  
%Usage:
%   minD = minDistBlock(pts1, pts2, blockSize);
%
% Copyright 2010, Joseph O. Deasy, on behalf of the CERR development team.
% 
% This file is part of The Computational Environment for Radiotherapy Research (CERR).
% 
% CERR development has been led by:  Aditya Apte, Divya Khullar, James Alaly, and Joseph O. Deasy.
% 
% CERR has been financially supported by the US National Institutes of Health under multiple grants.
% 
% CERR is distributed under the terms of the Lesser GNU Public License. 
% 
%     This version of CERR is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
% CERR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
% without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with CERR.  If not, see <http://www.gnu.org/licenses/>.

%Set default blockSize if needed.
if ~exist('blockSize')
    
    blockSize = 5E6;
end

%Get number of points in each set.
n1 = size(v1, 1);
n2 = size(v2, 1);

%Get number of dimensions in each set.
ndim1 = size(v1, 2);
ndim2 = size(v2, 2);
if ndim1 ~= ndim2
    error('minDistBlock: both point sets must have the same number of dimensions.')
end

%If block processing needed, make n1 the smallest point set.
if(n1*n2>blockSize), 
    if(n1>n2), 
        tmp = v2;
        v2 = v1;
        v1 = tmp;
        clear tmp;
        n1 = size(v1, 1);
        n2 = size(v2, 1);
    end
end

%If both point sets have more than blockSize elements...
if(n1>blockSize & n2>blockSize),
    message = ['minDistBlock: Both point sets are larger than blockSize. Calculation may take awhile.  BlockSize can be increased from ' num2str(blockSize) '.']; 
    warning(message);
    minD = Inf; 
    blockStep = blockSize;
    numBlocks =  ceil(n1/blockStep);
    for i = 1:numBlocks, 
        cntr1 = (i-1)*blockStep+1;
        cntr2 = min(i*blockStep, n1);
        for j = 1:n2, 
            rTmpSq = sepsq(v1(cntr1:cntr2, :)', v2(j, :)');
            minD = min(minD, min(rTmpSq(:)));
        end
    end

%If one set has less than blockSize elements...
else
    minD = Inf; 
    blockStep = floor(blockSize/n1);
    numBlocks = ceil(n2/blockStep);
    
    for i = 1:numBlocks
        cntr1 = (i-1)*blockStep+1;
        cntr2 = min(i*blockStep, n2);
        rTmpSq = sepsq(v1', v2(cntr1:cntr2,:)');
        minTmp = min(rTmpSq(:));
        minD = min(minD, minTmp);
    end
    
end    

%Convert back to sqrt since sepsq does not take sqrt.
minD = sqrt(minD);