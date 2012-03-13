function [contour, sliceValues] = maskToPoly(mask, sliceValues, scanNum, planC)
%"maskToPoly"
%   convert a 3D or 2D mask to a set of vertices denoting its contour lines.
%
%   By JRA 10/1/03
%
%   mask       : 2D or 3D matrix to convert
%   sliceValues: vector of CT slice numbers corresponding to each z element in the
%                mask, if mask is one slice sliceValues is just that slice's
%               num.
%   planC      : planC file used to convert from pixel values to real xyz coordinates
%
%   contour    : struct array consisting of segments, one for each slice evaluated.
%   sliceValues: index of slices into coutour, just as the input was.
%
%Usage: [contour, sliceValues] = maskToPoly(mask, sliceValues, planC)
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

[ySize, xSize, zSize] = size(mask);

for i=1:zSize
    slice = zeros(size(mask(:,:,i))+2);
    slice(2:end-1, 2:end-1) = double(mask(:,:,i));
    rawData = contourc(slice, [.5 .5]); %Contour lies between 0 and 1s
    contourData = postProcess(rawData, sliceValues(i), scanNum, planC);
    contour(i).segments = contourData;
end


function data = postProcess(contourData, slicenum, scanNum, planC)      
    i=1;
    data = [];
    if isempty(contourData)
        data.points = [];
        return;
    end
    while ~isempty(contourData)
        numPoints = contourData(2,1);
        xyData = contourData(:,2:numPoints+1)';
        column = xyData(:,1) - 1;
        row = xyData(:,2) - 1;
        [xData, yData, zValue] = mtoxyz(row, column, slicenum, scanNum, planC);        
        zData = ones(numPoints,1)*zValue;
        data(i).points = [xData, yData, zData];
        contourData(:,1:numPoints+1) = [];
        i = i+1;
    end