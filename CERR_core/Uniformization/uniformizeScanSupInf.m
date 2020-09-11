function planC = uniformizeScanSupInf(planC, tMin, tMax, optS, hBar, scanNumV)
%"uniformizeScanSupInf"
%    Creates the superior and inferior scan arrays so that they 
%   are uniform, consistent with the rest of the scan array.
%
%Latest modifications:
% 16 Aug 02, V H Clark, first version.
% 09 Apr 03, JOD, added hBar to input parameter list.
% 18 Feb 05, JRA, Added support for multiple scans.
%
%Usage:
%   function planC = uniformizeScanSupInf(planC, tMin, tMax, optS, hBar)
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

% Get scan indices
if ~exist('scanNumV','var')
    scanNumV = 1:length(planC{indexS.scan});
end

for scanNum = scanNumV
    
    scanStruct = planC{indexS.scan}(scanNum);
    
	uniformScanInfo = planC{indexS.scan}(scanNum).uniformScanInfo;
	sliceNumSup = uniformScanInfo.sliceNumSup; %superior slice number of original CT scan still being used
	sliceNumInf = uniformScanInfo.sliceNumInf; %inferior slice number of original CT scan still being used
	uniformSliceThickness = uniformScanInfo.sliceThickness;
	%scanArray = planC{indexS.scan}(scanNum).scanArray;
	%scanInfo = planC{indexS.scan}(scanNum).scanInfo;
	
	[scanArraySup, scanArrayInf, uniformScanFirstZValue] = ...
        uniformizeScanEnds(scanStruct, sliceNumSup, sliceNumInf,...
        uniformSliceThickness, tMin, tMax, optS, hBar);
	
	uniformScanInfo.firstZValue = uniformScanFirstZValue;
	uniformScanInfo.supInfScansCreated = 1;
	
	planC{indexS.scan}(scanNum).scanArraySuperior = scanArraySup;
	planC{indexS.scan}(scanNum).scanArrayInferior = scanArrayInf;
	
	planC{indexS.scan}(scanNum).uniformScanInfo = uniformScanInfo;	
end


