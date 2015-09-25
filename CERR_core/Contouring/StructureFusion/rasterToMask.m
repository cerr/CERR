function [dataSet, uniqueSlices] = rasterToMask(rasterSegments, scanNum, planC)
%"rasterToMask"
%   Convert a list of raster segments into a mask with inbetween slices
%   removed. sliceValues indicates the real CT slice number of each mask
%   slice. So if the given rasterSegments are on slices 1 and 50 only, a mask
%   with two slices is returned, and sliceValues is [1 50].
%
%By JRA 10/1/03
%
%rasterSegments:    List of rasterSegments to convert
%scanNum       :    Scan number rasterSegments are defined on.
%
%mask          :    what else? the mask.
%sliceValues   :    Array of CT values for each slice of mask.
%
%Usage:
%   [mask, sliceValues] = rasterToMask(rasterSegments, scanNum, planC)
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

if ~exist('planC')
    global planC
end

indexS = planC{end};

%Get x,y size of each slice in this scanset.
siz = size(getScanArray(planC{indexS.scan}(scanNum)));
x = siz(2);
y = siz(1);

%If no raster segments return empty mask.
if isempty(rasterSegments)
    dataSet = repmat(logical(0), [y,x]);
    uniqueSlices = [];
    return;
end

%Figure out how many unique slices we need.
uniqueSlices = unique(rasterSegments(:, 6));
nUniqueSlices = length(uniqueSlices);
dataSet = repmat(logical(0), [y,x,nUniqueSlices]);

%Loop over raster segments and fill in the proper slice.
for i = 1:size(rasterSegments,1)    
    CTSliceNum = rasterSegments(i,6);
    index = find(uniqueSlices == CTSliceNum);
    dataSet(rasterSegments(i,7), rasterSegments(i,8):rasterSegments(i,9), index) = 1;
end 