function minD = minDistBinned(pts1, pts2, binSize, blockSize);
%"minDistBinned"
%   Returns the minimum distance between two sets of points in n-D space.
%   Points are specified as a matrix size nPts x nDims, ie for 10 points in
%   3 dimensions, 10x3.
%
%   minDistBinned bins the point data in an attempt to throw away a
%   significant number of points.  For two large point sets that are
%   somehwat seperated from each other in space and whose points are not
%   all nearly equidistant from the other surface (concentric cylinders, 
%   spheres, margins) this binning results in significant improvements in
%   calculation time.  
%
%   An optional parameter, binSize, sets the size of the bins.  If not passed, 
%   the default of .5 is used.
%
%   minDistBinned uses minDistBlock for the actual distance calculation.  
%   The optional blockSize parameter to be passed into minDistBlock can be 
%   passed in to this function, if it does not exist no blockSize is passed
%   to minDistBlock and it uses its default (usually 5E6).
%
% PEL 04/22/05
%  
%Usage:
%   minD = minDistBinned(pts1, pts2, binSize, blockSize);
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


if ~exist('binSize')      
    binSize = 0.5;
end

%Factor to multiply all points by to simulate binSize.
multFact = 1/binSize;

%Get number of points in each set.
n1 = size(pts1, 1);
n2 = size(pts2, 1);

%Get number of dimensions in each set.
ndim1 = size(pts1, 2);
ndim2 = size(pts2, 2);
if ndim1 ~= ndim2
    error('minDistBinned: both point sets must have the same number of dimensions.')
end

%Find the minimum value in each dim.
minVal = min(min(pts1), min(pts2));

%Bin the points, subtracting the minVal to reduce binNumber.
pts1New = round(pts1.*multFact) - repmat(round(minVal*multFact), [n1, 1]) + 1;
pts2New = round(pts2.*multFact) - repmat(round(minVal*multFact), [n2, 1]) + 1;

%Get unique bins.
[unique1, i1, j1] = unique(pts1New, 'rows');
[unique2, i2, j2] = unique(pts2New, 'rows');

%Find squared distance between bins in each set.
rTmpSq = sepsq(unique1', unique2');

%Get threshold distance: 2*cornerToCorner distance of nDim "cube".
minD = sqrt(min(rTmpSq(:))) + 2*sqrt(ndim1);

%Keep any bins with min distances less than minD.
pointsToKeep = rTmpSq<=minD^2;

%Filter by the bins kept.
v2 = find(any(pointsToKeep, 1));
v1 = find(any(pointsToKeep, 2));
uniqueValsToKeep1 = unique1(intersect(j1, v1), :);
uniqueValsToKeep2 = unique2(intersect(j2, v2), :);
[ia] = ismember(pts1New, uniqueValsToKeep1, 'rows');
[ib] = ismember(pts2New, uniqueValsToKeep2, 'rows');

%Calculate distance between remaining points in the 2 sets.
if exist('blockSize')
    minD =  minDistBlock(pts1(ia, :), pts2(ib, :), blockSize);
else
    minD =  minDistBlock(pts1(ia, :), pts2(ib, :));
end