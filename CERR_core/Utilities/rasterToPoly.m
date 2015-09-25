function contour = rasterToPoly(rasterSegments, scanNum, planC)
%"rasterToPoly"
%   Convert a list of raster segments into contours, one slice at a time
%   in order to save memory and increase speed.
%
%   By JRA 10/1/03
%
%   rasterSegments:    List of rasterSegments to convert
%   scanNum       :    Scan number the rasterSegments are associated with.
%   planC         :    the planC
%
%   contour       :    typical CERR contour structure.
%
% Usage:
%   contour = rasterToPoly(rasterSegments, scanNum, planC)
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

if isempty(rasterSegments)
    contour = [];
    return
end

indexS = planC{end};
[xSize,ySize,zSize] = size(getScanArray(planC{indexS.scan}(scanNum)));

%sort input rasterSegments by CTSliceValue
rasterSegments = sortrows(rasterSegments, 6);

%get list of CTSlices to iterate over.
slicesToCalculate = unique(rasterSegments(:,6));

for sliceNum = 1:zSize
    if any(slicesToCalculate==sliceNum);
        rasterIndices = find(rasterSegments(:,6) == sliceNum);
        mask = rasterToMask(rasterSegments(rasterIndices,:), scanNum, planC);
        contour(sliceNum) = maskToPoly(mask, sliceNum, scanNum, planC);
    else
        contour(sliceNum).segments.points = [];
    end
end
if length(contour) ~= zSize
    contour(zSize).segments.points = [];
end