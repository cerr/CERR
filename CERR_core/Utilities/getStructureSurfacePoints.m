function [surfPoints, planC] = getStructureSurfacePoints(structNum, makeUniform, planC)
%"getStructureSurfacePoints"
%   Return the [row,col,slice] of the surface points of CERR structure
%   <structNum>'s uniformized representation. A surface point is defined 
%   as any voxel in the structure that is adjacent to a voxel not in the 
%   structure.  Two voxels are considered adjacent when their faces touch, 
%   and NOT adjacent if only their corners or edges touch.
%
% 	makeUniform is an optional parameter which determines if the
%   uniformized data should be generated cases where it does not
%   already exist. 'yes' by default.
%         'no'        = do not generate.
%         'yes'       = generate.
%         'prompt'    = ask user if they want to generate.
%
%   planC is an optional parameter.  If it is not passed the global planC
%   is used.
%
%   This function does not use getUniformStr + getSurfacePoints so that it
%   operates as quickly as possible, for use in a beams eye view module.
%
% JRA 03/23/05 - Created this function for Beams Eye View.
%
% Usage:
%   [surfPoints] = getStructureSurfacePoints(structNum)
%   [surfPoints, planC] = getStructureSurfacePoints(structNum, makeUniform, planC)
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

surfPoints = [];

%Check if plan passed, if not use global.
if ~exist('planC')
    global planC;
end

if ~exist('makeUniform')
    makeUniform = 'prompt';
end

indexS = planC{end};

%Determine which scanSet this structure is registered to.
[scanNum, relStructNum] = getStructureAssociatedScan(structNum, planC);
scanNum = unique(scanNum);

%Grab the uniformized data.
%[indicesM, bitsM, planC] = getUniformizedData(planC, scanNum, makeUniform);
[indicesC, structBitsC, planC] = getUniformizedData(planC, scanNum);
if relStructNum <= 52
    bitsM = structBitsC{1};
    indicesM = indicesC{1}; 
else
    cellNum = ceil((relStructNum-52)/8)+1;
    bitsM = structBitsC{cellNum};
    indicesM = indicesC{cellNum}; 
end

%Get the uniformized data's dimensions
siz = getUniformScanSize(planC{indexS.scan}(scanNum));

numRows = siz(1);
numCols = siz(2);
numSlcs = siz(3);

%Initialize mask3M, the full structure mask.
mask3M = logical(repmat(logical(0), siz));

%Eliminate uniformized data that lies outside the defined region.
indDeleteV = indicesM(:,3) > numSlcs;
bitsM(indDeleteV,:) = [];
indicesM(indDeleteV,:) = [];

%Get values corresponding to requested structNum.
maskV = logical(bitget(bitsM(:),relStructNum));
clear bitsM;

%Grab the r,c,s rows where the structure exists.
otherIndices = indicesM(maskV, :);
clear maskV;

%Return if we are empty, the matrix is all zeros.
if isempty(otherIndices)
    warning('Requested structure does not appear to be uniformized.');
    return;
end

%Convert 3d indices to vectorized indices.
indexV = double(otherIndices(:,1)) + (double(otherIndices(:,2))-1)*numRows + (double(otherIndices(:,3))-1)*(numRows*numCols);

%Get the extents of the structure for future use.
minInd = double(min(otherIndices));
maxInd = double(max(otherIndices));
clear otherIndices;

%Fill mask3M in with values where the structure exists.
mask3M(indexV) = 1;
clear indexV;

%Find minimum rows, cols, slices.
minR = minInd(1); maxR = maxInd(1);
minC = minInd(2); maxC = maxInd(2);
minS = minInd(3); maxS = maxInd(3);

%Restrict surface calculation to region with structure.
mask3M = mask3M(minR:maxR, minC:maxC, minS:maxS);

%Construct the "allNeighborsOn" matrix, which for any voxel not on the edge
%of maskM, tells whether or not ALL of its neighbors are on.
plusRowShift  = mask3M(3:end, 2:end-1, 2:end-1);
allNeighborsOn = plusRowShift;
clear plusRowShift

minusRowShift = mask3M(1:end-2, 2:end-1, 2:end-1);
allNeighborsOn = allNeighborsOn & minusRowShift;
clear minusRowShift

plusColShift  = mask3M(2:end-1, 3:end, 2:end-1);
allNeighborsOn = allNeighborsOn & plusColShift;
clear plusColShift

minusColShift = mask3M(2:end-1, 1:end-2, 2:end-1);
allNeighborsOn = allNeighborsOn & minusColShift;
clear minusColShift

plusSlcShift  = mask3M(2:end-1, 2:end-1, 3:end);
allNeighborsOn = allNeighborsOn & plusSlcShift;
clear plusSlcShift

minusSlcShift = mask3M(2:end-1, 2:end-1, 1:end-2);
allNeighborsOn = allNeighborsOn & minusSlcShift;
clear minusSlcShift

%Now find all surface points (except those on the edge of maskM), defined
%as those points that are ON in mask3M and don't have ALL 6 of their 
%neighbors on.
kernal = mask3M(2:end-1, 2:end-1, 2:end-1) & ~allNeighborsOn;

%Finally drop the kernal back into the middle of mask3M.  All points on the
%first/last row, column and slice of mask3M are by definion surface points.
mask3M(2:end-1, 2:end-1, 2:end-1) = kernal;

%Find the location of the surface points.
[r,c,s] = find3d(mask3M);

%Correct for taking a subset of mask3M when we began.
r = r + (minR - 1);
c = c + (minC - 1);
s = s + (minS - 1);

surfPoints = [r;c;s]';