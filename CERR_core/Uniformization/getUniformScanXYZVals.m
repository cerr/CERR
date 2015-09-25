function [xVals, yVals, zVals] = getUniformScanXYZVals(scanStruct)
%"getUniformScanXYZVals"
%   Return the X Y and Z vals of the uniformized scan from the passed
%   scanStruct.
%
%   These are arrays, with a value for each row, col and slice in the
%   uniformized dataset.
%
%   In case of any error accessing the data 0 is returned for all vals.
%
% JRA 11/17/04
%
% Usage: [xVals, yVals, zVals] = getUniformScanXYZVals(scanStruct)
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


scanInfo = scanStruct.scanInfo(1);

sizeDim1 = scanInfo.sizeOfDimension1-1;
sizeDim2 = scanInfo.sizeOfDimension2-1;

MATLABVer = version;
if MATLABVer(1) ~= '6'
    sizeDim1 = double(sizeDim1);
    sizeDim2 = double(sizeDim2);
    sizeArray = double(getUniformScanSize(scanStruct));
else
    sizeArray = getUniformScanSize(scanStruct);    
end


xVals = scanInfo.xOffset - (sizeDim2*scanInfo.grid2Units)/2 : scanInfo.grid2Units : scanInfo.xOffset + (sizeDim2*scanInfo.grid2Units)/2;
yVals = fliplr(scanInfo.yOffset - (sizeDim1*scanInfo.grid1Units)/2 : scanInfo.grid1Units : scanInfo.yOffset + (sizeDim1*scanInfo.grid1Units)/2);



uniformScanInfo = scanStruct.uniformScanInfo;
nZSlices = sizeArray(3);
zVals = uniformScanInfo.firstZValue : uniformScanInfo.sliceThickness : uniformScanInfo.sliceThickness * (nZSlices-1) + uniformScanInfo.firstZValue;          