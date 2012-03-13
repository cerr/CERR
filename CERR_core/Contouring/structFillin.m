function rasterSegs = structFillin(rasterSegs1, scanNum, planC)
%"structFillin"
%   Take the rasterSegments from one structure and fill in all slices with
%   no defined structure.  Return the rasterSegments of the new filled in
%   structure.  Uses nearest neighbor interpolation to duplicate the
%   contours.
%
%   By JRA 1/7/05
%
%   rasterSegs1    : rasterSegments of a structure
%   planC          : CERR planC
%
%   rasterSegs     : rasterSegments of filled in structure
%
%Usage:
%   rasterSegs = structFillin(rasterSegs1, scanNum, planC)
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


indexS = planC{end};
rasterSegs = [];
[xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(scanNum));

%sort input rasterSegments by CTSliceValue
rasterSegs1 = sortrows(rasterSegs1, 6);

%get list of CTSlices to iterate over.
slices1 = unique(rasterSegs1(:,6));
minSlice = min(slices1);
maxSlice = max(slices1);

%Iterate over all slices.  If no rasterSegs exist on a slice, find the
%nearest slice, take its rasterSegs, modify them to fit the new
%slice/zvalue, and add them to the rasterSegs list.
for sliceNum = minSlice:maxSlice
    rasterIndices = find(rasterSegs1(:,6) == sliceNum);    
    if isempty(rasterIndices)
        sliceZValue = zV(sliceNum);        
        nearestDefinedSliceNum = interp1(zV(slices1), slices1, sliceZValue, 'nearest');
        tmpIndV = find(rasterSegs1(:,6) == nearestDefinedSliceNum);
        tmpSegsV = rasterSegs1(tmpIndV,:);
        tmpSegsV(:,1) = zV(sliceNum);
        tmpSegsV(:,6) = sliceNum;
        rasterSegs = [rasterSegs;tmpSegsV];    
    else
        rasterSegs = [rasterSegs;rasterSegs1(rasterIndices,:)];    
    end        
end