function [xVals, yVals, zVals] = getScanXYZVals(scanStruct, slice)
%"getScanXYZVals"
%   Returns the x, y, and z values of the cols, rows, and slices of the
%   passed scanStruct.  If specified, slice determines which element of
%   scanInfo is used to determine the x and y vals.  If slice is invalid or
%   not specified, 1 is used.
%
%   REMINDER: These x,y,z values are the coordinates of the MIDDLE of the
%   voxels of the scan.  They are not the coordinates of the dividers
%   between the voxels.
%
%   By JRA 12/26/03
%
%   scanStruct      : ONE planC{indexS.scan} struct.
%   slice           : slice to base x,y vals on
%
% xVals yVals zVals : x,y,z Values for scan.
%
% Usage:
%   function [xVals, yVals, zVals] = getScanXYZVals(scanStruct, slice)
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

if exist('slice','var')
    scanInfo = scanStruct.scanInfo(slice);
else
    scanInfo = scanStruct.scanInfo(1);
end

sizeDim1 = scanInfo.sizeOfDimension1-1;
sizeDim2 = scanInfo.sizeOfDimension2-1;

MATLABVer = version;
if MATLABVer(1) ~= '6'
    sizeDim1 = double(sizeDim1);
    sizeDim2 = double(sizeDim2);
end

xVals = scanInfo.xOffset - (sizeDim2*scanInfo.grid2Units)/2 : scanInfo.grid2Units : scanInfo.xOffset + (sizeDim2*scanInfo.grid2Units)/2;
yVals = fliplr(scanInfo.yOffset - (sizeDim1*scanInfo.grid1Units)/2 : scanInfo.grid1Units : scanInfo.yOffset + (sizeDim1*scanInfo.grid1Units)/2);
sI = scanStruct.scanInfo;
zVals = [sI.zValue];
