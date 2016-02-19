function planC = cropScan(scanNum,structureNum,margin,planC)
%function planC = cropScan(scanNum,structureNum,margin,planC)
%
%This function crops the scan scanNum to lie within the structure
%structureNum plus margin.
%
%Usage: 
% scanNum      = 1; % CT
% structureNum = 8; % Skin
% margin       = 2; % in cm
% planC = cropScan(scanNum,structureNum,margin,planC)
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

global stateS

if ~exist('planC','var')
    global planC
end
indexS = planC{end};

% for command line help document
if ~exist('scanNum') || ~exist('structureNum') || ~exist('margin')
    prompt = {'Enter the scan number';'Enter the structure number'; 'Enter the margin (cm)'};
    dlg_title = 'Crop scan';
    num_lines = 1;
    def = {'';'';''};
    outPutQst = inputdlg(prompt,dlg_title,num_lines,def);
    if isempty(outPutQst{1}) || isempty(outPutQst{2}) || isempty(outPutQst{3})
        warning('Need to enter all the inputs');
        return
    else
        scanNum         = str2num(outPutQst{1});
        structureNum    = str2num(outPutQst{2});
        margin          = str2num(outPutQst{3});
    end
end

%Record associated Doses to reassign UIDs later
assocScanV = getDoseAssociatedScan(1:length(planC{indexS.dose}),planC);
assocDoseV = find(assocScanV == scanNum);

%Get associated scan number
assocScanNum = getStructureAssociatedScan(structureNum,planC);
tmAssocScan = getTransM('scan',assocScanNum,planC);
tmScan = getTransM('scan',scanNum,planC);
if ~isequal(tmAssocScan,tmScan)
    error('This function currently supports dose and structure with same transformation matrix')
end

%Get scan grid
[xScanVals, yScanVals, zScanVals] = getScanXYZVals(planC{indexS.scan}(scanNum));

%Get structure boundary
rasterSegments = getRasterSegments(structureNum,planC);
zMin = min(rasterSegments(:,1)) - margin;
zMax = max(rasterSegments(:,1)) + margin;
xMin = min(rasterSegments(:,3)) - margin;
xMax = max(rasterSegments(:,4)) + margin;
yMin = min(rasterSegments(:,2)) - margin;
yMax = max(rasterSegments(:,2)) + margin;

%Get min, max indices of scanArray
[JLow, jnk] = findnearest(xScanVals, xMin);
[jnk, JHigh] = findnearest(xScanVals, xMax);
[jnk, ILow] = findnearest(yScanVals, yMin);
[IHigh, jnk] = findnearest(yScanVals, yMax);
[KLow, jnk] = findnearest(zScanVals, zMin);
[jnk, KHigh] = findnearest(zScanVals, zMax);

%Crop scanArray
planC{indexS.scan}(scanNum).scanArray = planC{indexS.scan}(scanNum).scanArray(IHigh:ILow,JLow:JHigh,KLow:KHigh);

sizeDim1 = length(IHigh:ILow);
sizeDim2 = length(JLow:JHigh);
xOffset = xScanVals(JLow) + (sizeDim2*planC{indexS.scan}(scanNum).scanInfo(1).grid2Units)/2;
yOffset = yScanVals(ILow) + (sizeDim1*planC{indexS.scan}(scanNum).scanInfo(1).grid1Units)/2;

%Reassign zvalues
for i=1:length(KLow:KHigh)
    %planC{indexS.scan}(scanNum).scanInfo(i).zValue = zScanVals(KLow+i-1);
    planC{indexS.scan}(scanNum).scanInfo(KLow+i-1).sizeOfDimension1 = sizeDim1;
    planC{indexS.scan}(scanNum).scanInfo(KLow+i-1).sizeOfDimension2 = sizeDim2;
    planC{indexS.scan}(scanNum).scanInfo(KLow+i-1).xOffset = xOffset;
    planC{indexS.scan}(scanNum).scanInfo(KLow+i-1).yOffset = yOffset;
end

planC{indexS.scan}(scanNum).scanInfo([1:KLow-1, KHigh+1:end]) = [];

assocScanV = getStructureAssociatedScan(1:length(planC{indexS.structures}), planC);

indAssocV = find(assocScanV == scanNum);

%Retain only structure slices which are present on new scan
for structNum = indAssocV
    planC{indexS.structures}(structNum).contour([1:KLow-1, KHigh+1:end]) = [];
    planC{indexS.structures}(structNum).rasterSegments = [];
end

%Create new UID since this scan has changed
oldScanUID = ['c',repSpaceHyp(planC{indexS.scan}(scanNum).scanUID(max(1,end-61):end))];
planC{indexS.scan}(scanNum).scanUID = createUID('scan');
for structNum = indAssocV
    planC{indexS.structures}(structNum).assocScanUID = planC{indexS.scan}(scanNum).scanUID;
    planC{indexS.structures}(structNum).strUID = createUID('structure');
end

%Reassociate Dose to cropped scan
for i=1:length(assocDoseV);
    planC{indexS.dose}(assocDoseV(i)).assocScanUID = planC{indexS.scan}(scanNum).scanUID;
end

planC = reRasterAndUniformize(planC);

if isfield(stateS,'scanSet')
    stateS.scanSet = scanNum;    
    % Update scan stats in stateS
    scanUID = ['c',repSpaceHyp(planC{indexS.scan}(scanNum).scanUID(max(1,end-61):end))];
    stateS.scanStats.minScanVal.(scanUID) = single(min(planC{indexS.scan}(scanNum).scanArray(:)));
    stateS.scanStats.maxScanVal.(scanUID) = single(max(planC{indexS.scan}(scanNum).scanArray(:)));
    stateS.scanStats.CTLevel.(scanUID) = stateS.scanStats.CTLevel.(oldScanUID);
    stateS.scanStats.CTWidth.(scanUID) = stateS.scanStats.CTWidth.(oldScanUID);
    stateS.scanStats.windowPresets.(scanUID) = stateS.scanStats.windowPresets.(oldScanUID);
    stateS.scanStats.Colormap.(scanUID) = stateS.scanStats.Colormap.(oldScanUID);    
    sliceCallBack('refresh');
end
