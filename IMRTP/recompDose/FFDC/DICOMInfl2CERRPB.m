function [inflMask, xV, yV, xMin, xMax, yMin, yMax] = DICOMInfl2CERRPB(inflMap, colXCoord, rowYCoord, PBSizeX, PBSizeY)
%"DICOMInfl2CERRPB"
%   Converts DICOM beam influence map to CERR PBs with weights.
%
%   PBSizeX, Y are in cm.
%
%JRA&KZ 02/8/05
%
%Usage:
%   function DICOMInfl2CERRPB(inflMap, colXCoord, rowYCoord)
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

colSize = abs(colXCoord(2) - colXCoord(1));
nColsInFilter = ceil(10*PBSizeX / colSize);
gaussianMidWidth = floor(nColsInFilter/6);

if nColsInFilter > 1
    filter = fspecial('gaussian', [1 nColsInFilter], gaussianMidWidth);
    inflMap = imfilter(inflMap, filter);
end

xMin = min(colXCoord)/10;
xMax = max(colXCoord)/10;
yMin = min(rowYCoord)/10;
yMax = max(rowYCoord)/10;

xV = xMin*10:PBSizeX*10:xMax*10;
yV = yMin*10:PBSizeY*10:yMax*10;

xV(end+1) = xMax*10;
yV(end+1) = yMax*10;

% [x y] = meshgrid(colXCoord, rowYCoord);
% [xi yi] = meshgrid(xV, yV);

%zi = interp2(x, y, inflMap, xi, yi, 'linear');

zi = finterp2(colXCoord, rowYCoord, inflMap, xV, yV, 1);
inflMask = zi;
% figure;imagesc(inflMask);