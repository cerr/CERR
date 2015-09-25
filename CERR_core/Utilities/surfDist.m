function dist = surfDist(numStr1, numStr2, planC, blockSize)
%"surfDist"
%   Returns the minimum distance in cm between the surfaces of two
%   (uniformized) structures in planC.
%
%   blockSize is an optional argument that specifies how many points from
%   the larger set are examined at a time.  If left empty blockSize is
%   determined automatically.
%
%   JRA 3/31/04
%   JRA 4/08/04 - Added block processing
%
%Usage:
%   function dist = surfDist(numStr1, numStr2, planC)
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

if ~exist('blockSize')
	blockSize = 'auto';
    maxMatrixSize = 1000000;
end  

%Get uniform masks of each str.
str1 = getUniformStr(numStr1);
surf1 = getSurfacePoints(str1);
clear str1;

str2 = getUniformStr(numStr2);
surf2 = getSurfacePoints(str2);
clear str2;

%If any point is common to both sets, dist is 0.
if any(ismember(surf1, surf2, 'rows'))
    dist = 0;
    return;
end

%Get x,y,z values of the uniformizedData, (is in cm).
indexS = planC{end};
[xVals, yVals, zVals] = getUniformizedXYZVals(planC);

%Get the coordinates of the surface voxels for both sets.
ptset1 = [yVals(surf1(:,1));xVals(surf1(:,2));zVals(surf1(:,3))];
ptset2 = [yVals(surf2(:,1));xVals(surf2(:,2));zVals(surf2(:,3))];

%Set the larger set of points to be pointset 2, for most efficent blocking.
if size(ptset1, 2) > size(ptset2, 2)
    tmp = ptset2;
    ptset2 = ptset1;
    ptset1 = tmp;
    clear tmp
end

nPts2 = size(ptset2, 2);

%If auto, determine best blocksize, assuming less than maxMatrixSize element matrix.
if ischar(blockSize) & strcmpi(blockSize, 'auto');
    blockSize = min(floor(maxMatrixSize / nPts2), nPts2);
    if blockSize == 0
        blockSize = 1;
    end
end

%Block and extract min dist from each block.
runningMin = Inf;
for i=1:nPts2/blockSize
    
    blk = [(i-1)*blockSize+1:min(nPts2, (i-1)*blockSize+blockSize)];
    blkPts2 = ptset2(:, blk);
    matrix = sepsq(ptset1, blkPts2);
    runningMin = min(min(matrix(:)), runningMin);
end

%Find the minimum distance.
dist = sqrt(runningMin);