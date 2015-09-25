function totalEnergy = getEnergyDeposited(planC,structNum,doseNum)
%function getEnergyDeposited(planC,structNum,doseNum)
%
%This function computes the total Energy deposited within a structure.
%
%APA, 04/21/2010
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

global stateS
stateS.optS = CERROptions;
stateS.MLVersion = getMLVersion;

indexS = planC{end};

scanNum = getStructureAssociatedScan(structNum,planC);

%Get Uniformized dose matrix within the structure structNum
dose3M = getUniformDose(doseNum, scanNum, structNum, planC);

numVoxels = length(find(dose3M > 0));

%Get Uniformized scan matrix for scanNum
scan3M = getUniformizedCTScan(1, scanNum, planC);

[xV,yV,zV] = getUniformScanXYZVals(planC{indexS.scan}(scanNum));

dx = abs(xV(1)-xV(2));
dy = abs(yV(1)-yV(2));
dz = abs(zV(1)-zV(2));

voxelVolume = dx * dy * dz;

totalEnergy = sum(dose3M(:).*scan3M(:))*voxelVolume*numVoxels;
