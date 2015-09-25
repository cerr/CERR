function surfPoints = getSurfacePoints(mask3M)
%"getSurfacePoints"
%   Return the [row,col,slice] of surface points in mask3M, where a surface
%   point is defined as any voxel in the structure that is adjacent to a
%   voxel not in the structure.  Two voxels are considered adjacent when
%   their faces touch, and NOT adjacent if only their corners or edges
%   touch.
%
%   To create the 3D surface analog of mask3M use:
%
%   surfPoints = getSurfacePoints(mask3M);
%   surf3M = repmat(logical(0), size(mask3M));
%   for i=1:size(surfPoints,1)
%        surf3M(surfPoints(i,1),surfPoints(i,2), surfPoints(i,3)) = 1;
%   end
%
%   Constructing a 2nd 3D mask the size of mask3M may pose a memory
%   problem, so substituting mask3M for surf3M is a good idea if 
%   mask3M is disposable.
%
% JRA 11/20/03
%     03/23/05 - New algorithm for speed, ~10x faster
%
% Usage: surfPoints = getSurfacePoints(mask3M)
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

[r,c,s] = find3d(mask3M);

%Find minimum rows, cols, slices.
minR = min(r); maxR = max(r);
minC = min(c); maxC = max(c);
minS = min(s); maxS = max(s);

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
%as those points that are ON in mask3M and don't have ALL their neighbors
%on.
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