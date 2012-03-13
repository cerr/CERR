function scanStruct = setScanXYZVals(scanStruct, xVals, yVals, zVals);
%"setScanXYZVals"
%   Sets the x, y, and z values of the cols, rows, and slices of the
%   passed scanStruct.  
%
%   xVals must be EVENLY spaced and INCREASING.
%   yVals must be EVENLY spaced and DECREASING.
%   zVals must be simply INCREASING.
%
%   By JRA 1/26/05
%
%   scanStruct        : a planC{indexS.scan} struct.
%   xVals yVals zVals : new x,y,z values for scan.
%
% Usage:
%   function scanStruct = setScanXYZVals(scanStruct, xVals, yVals, zVals);
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


scanSize = size(getScanArray(scanStruct));
if length(xVals) ~= scanSize(2)
    error('Invalid number of xVals, must have the same number as columns in scanArray.');
end
if length(yVals) ~= scanSize(1)
    error('Invalid number of yVals, must have the same number as rows in scanArray.');
end
if length(zVals) ~= scanSize(3)
    error('Invalid number of zVals, must have the same number as slices in scanArray.');
end

sizeDim1 = scanSize(1);
sizeDim2 = scanSize(2);
sizeDim3 = scanSize(3);

grid2Units = xVals(2) - xVals(1);
grid1Units = -(yVals(2) - yVals(1));

for i=1:scanSize(3)
    scanStruct.scanInfo(i).grid1Units = grid1Units;
    scanStruct.scanInfo(i).grid2Units = grid2Units;    
    scanStruct.scanInfo(i).sizeOfDimension1 = sizeDim1;
    scanStruct.scanInfo(i).sizeOfDimension2 = sizeDim2;    
    scanStruct.scanInfo(i).zValue = zVals(i);
    scanStruct.scanInfo(i).xOffset = mean(xVals);
    scanStruct.scanInfo(i).yOffset = mean(yVals);
end

scanStruct.uniformScanInfo.grid1Units = grid1Units;
scanStruct.uniformScanInfo.grid2Units = grid2Units;    
scanStruct.uniformScanInfo.sizeOfDimension1 = sizeDim1;
scanStruct.uniformScanInfo.sizeOfDimension2 = sizeDim2;    
scanStruct.uniformScanInfo.zValue = zVals(i);
scanStruct.uniformScanInfo.xOffset = mean(xVals);
scanStruct.uniformScanInfo.yOffset = mean(yVals);
scanStruct.uniformScanInfo.firstZValue = scanStruct.scanInfo(1).zValue;