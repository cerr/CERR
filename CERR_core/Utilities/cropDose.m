function cropDose(doseNum,structureNum,margin)
%function cropDose(doseNum,structureNum,margin)
%
%This function crops the dose doseNum to lie within the structure
%structureNum plus margin.
%
%Usage: 
% doseNum      = 1; %final
% structureNum = 8; %skin
% margin       = 2; %cm
% cropDose(doseNum,structureNum,margin)
%
%APA, 07/03/2010
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

% for command line help document
if ~exist('doseNum') || ~exist('structureNum') || ~exist('margin')
    prompt = {'Enter the dose number';'Enter the structure number'; 'Enter the margin (cm)'};
    dlg_title = 'Crop scan';
    num_lines = 1;
    def = {'';'';''};
    outPutQst = inputdlg(prompt,dlg_title,num_lines,def);
    if isempty(outPutQst{1}) || isempty(outPutQst{2}) || isempty(outPutQst{3})
        warning('Need to enter all the inputs');
        return
    else
        doseNum         = str2num(outPutQst{1});
        structureNum    = str2num(outPutQst{2});
        margin          = str2num(outPutQst{3});
    end
end

%Get associated scan number
scanNum = getStructureAssociatedScan(structureNum);
assocScanUID = planC{indexS.dose}(doseNum).assocScanUID;
scanNumDose = getAssociatedScan(assocScanUID);
tmDose = getTransM('dose',doseNum,planC);
tmScan = getTransM('scan',scanNum,planC);
if isempty(scanNumDose) && ~isequal(tmDose,tmScan)
    error('This function currently supports dose and structure with same transformation matrix')
end

%Get dose grid
[xDoseVals, yDoseVals, zDoseVals] = getDoseXYZVals(planC{indexS.dose}(doseNum));

%Get structure boundary
rasterSegments = getRasterSegments(structureNum,planC);
zMin = min(rasterSegments(:,1)) - margin;
zMax = max(rasterSegments(:,1)) + margin;
xMin = min(rasterSegments(:,3)) - margin;
xMax = max(rasterSegments(:,4)) + margin;
yMin = min(rasterSegments(:,2)) - margin;
yMax = max(rasterSegments(:,2)) + margin;

%Get min, max indices of DoseArray
[JLow, jnk] = findnearest(xDoseVals, xMin);
[jnk, JHigh] = findnearest(xDoseVals, xMax);
[jnk, ILow] = findnearest(yDoseVals, yMin);
[IHigh, jnk] = findnearest(yDoseVals, yMax);
[KLow, jnk] = findnearest(zDoseVals, zMin);
[jnk, KHigh] = findnearest(zDoseVals, zMax);

%Crop DoseArray
planC{indexS.dose}(doseNum).doseArray = planC{indexS.dose}(doseNum).doseArray(IHigh:ILow,JLow:JHigh,KLow:KHigh);

%Reassign zvalues
planC{indexS.dose}(doseNum).zValues = planC{indexS.dose}(doseNum).zValues(KLow:KHigh);

%Reassign coordinates of left corner
planC{indexS.dose}(doseNum).coord1OFFirstPoint = xDoseVals(JLow);
planC{indexS.dose}(doseNum).coord2OFFirstPoint = yDoseVals(IHigh);

%Reassign Dimension
planC{indexS.dose}(doseNum).sizeOfDimension2 = length(IHigh:ILow);
planC{indexS.dose}(doseNum).sizeOfDimension1 = length(JLow:JHigh);
planC{indexS.dose}(doseNum).sizeOfDimension3 = length(KLow:KHigh);

%Create new UID since this dose has changed
planC{indexS.dose}(doseNum).doseUID = createUID('dose');

stateS.doseSet = doseNum;
stateS.doseSetChanged = 1;

sliceCallBack('refresh');
