function chopDoseOutsideStruct(doseNum,structureNum)
%function chopDoseOutsideStruct(doseNum,structureNum)
%
%This function creates a new dose which is same as doseNum, but which lies
%within structureNum.
%
%Usage: planC = chopDoseOutsideStruct(1,6)
%
%APA, 04/01/2010
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

global stateS planC
indexS = planC{end};

%Get associated scan number
scanNum = getStructureAssociatedScan(structureNum);
assocScanUID = planC{indexS.dose}(doseNum).assocScanUID;
scanNumDose = getAssociatedScan(assocScanUID);
tmDose = getTransM('dose',doseNum,planC);
if isempty(tmDose)
    tmDose = eye(4);
end
tmScan = getTransM('scan',scanNum,planC);
if isempty(tmScan)
    tmScan = eye(4);
end
if isempty(scanNumDose) && ~isequal(tmDose,tmScan)
    error('This function currently supports dose and structure with same transformation matrix')
end

%Get dose grid
[xDoseVals, yDoseVals, zDoseVals] = getDoseXYZVals(planC{indexS.dose}(doseNum));

%Get Uniformized structure and grid
[xUnifVals, yUnifVals, zUnifVals] = getUniformScanXYZVals(planC{indexS.scan}(scanNum));
structureMask3M = getUniformStr(structureNum);

[xDoseValsM, yDoseValsM, zDoseValsM] = meshgrid(xDoseVals, yDoseVals, zDoseVals);
xDoseValsV = xDoseValsM(:);
yDoseValsV = yDoseValsM(:);
zDoseValsV = zDoseValsM(:);

%Interpolate structure on to dose grid
structureOnDoseV = interp3(xUnifVals, yUnifVals, zUnifVals, single(structureMask3M), xDoseValsV, yDoseValsV, zDoseValsV, 'nearest',0);

structureOnDoseM = reshape(structureOnDoseV,[length(yDoseVals), length(xDoseVals), length(zDoseVals)]);

planC{indexS.dose}(end+1) = planC{indexS.dose}(doseNum);
planC{indexS.dose}(end).doseArray = planC{indexS.dose}(end).doseArray .* structureOnDoseM;
planC{indexS.dose}(end).doseUID = createUID('dose');

stateS.doseSet = length(planC{indexS.dose});

sliceCallBack('refresh');
