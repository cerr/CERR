function [sizeArray, planC] = getUniformizedSize(planC)
%"getUniformizedSize"
%   Return the size of the uniformized dataset ([x y z]) and store it in
%   planC{indexS.scan}.uniformScanInfo.size for future reference.
%
%   If the uniformized data does not exist, returns and stores [0 0 0].
%
% JRA 11/14/03
%
% Usage: [sizeArray, planC] = getUniformizedSize(planC)
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

try
	uniformScanInfo = planC{indexS.scan}(1).uniformScanInfo;
	scanInfo = planC{indexS.scan}(1).scanInfo(1);
	
	%Find number of slices in whole uniformized set.
	nCTSlices = abs(uniformScanInfo.sliceNumSup - uniformScanInfo.sliceNumInf) + 1;
	nSupSlices = size(planC{indexS.scan}(1).scanArraySuperior, 3);
	if isempty(planC{indexS.scan}(1).scanArraySuperior), nSupSlices = 0;, end
	nInfSlices = size(planC{indexS.scan}(1).scanArrayInferior, 3);
	if isempty(planC{indexS.scan}(1).scanArrayInferior), nInfSlices = 0;, end
	zSize = nCTSlices + nSupSlices + nInfSlices;
	xSize = scanInfo(1).sizeOfDimension2;
	ySize = scanInfo(1).sizeOfDimension1;

    uniformScanInfo.size = [ySize xSize zSize];
    planC{indexS.scan}(1).uniformScanInfo = uniformScanInfo;
catch
    planC{indexS.scan}(1).uniformScanInfo.size = [0 0 0];
end

sizeArray = planC{indexS.scan}(1).uniformScanInfo.size;