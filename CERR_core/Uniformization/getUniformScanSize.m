function sizeArray = getUniformScanSize(scanStruct)
%"getUniformScanSize"
%   Return the size of the uniformized scan ([x y z]) for the passed
%   scanStruct.
%
%   If the uniformized data does not exist, returns [0 0 0].
%
% JRA 11/17/04
%
% Usage:
%   function sizeArray = getUniformScanSize(scanStruct)
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

try
	uniformScanInfo = scanStruct.uniformScanInfo;
	scanInfo = scanStruct.scanInfo(1);
    
    %Find number of slices in whole uniformized set.
    nCTSlices = abs(uniformScanInfo.sliceNumSup - uniformScanInfo.sliceNumInf) + 1;
    %Use scan access function in case of remote variables.
    scanArraySup    = getScanArraySuperior(scanStruct);
    scanArrayInf    = getScanArrayInferior(scanStruct);
    nSupSlices = size(scanArraySup, 3);
	if isempty(scanArraySup), nSupSlices = 0; end
	nInfSlices = size(scanArrayInf, 3);
	if isempty(scanArrayInf), nInfSlices = 0; end
	zSize = nCTSlices + nSupSlices + nInfSlices;
	xSize = scanInfo(1).sizeOfDimension2;
	ySize = scanInfo(1).sizeOfDimension1;

    uniformScanInfo.size = [ySize xSize zSize];
    scanStruct.uniformScanInfo = uniformScanInfo;
catch
    scanStruct.uniformScanInfo.size = [0 0 0];
end

sizeArray = scanStruct.uniformScanInfo.size;
MATLABVer = version;
if MATLABVer(1) ~= '6'
    sizeArray = double(sizeArray);
end
