function gEUD = gEUD2Dose(a,structNum,doseNum,nFlag)
%function gEUD = gEUD2Dose(a,structNum,doseNum)
%
%This function computes relative voxel contribution to gEUD and stores it
%as a new Dose distribution within planC.
%
%INPUT:
%   a           : exponent to compute gEUD
%   structNum   : structure number
%   doseNum     : dose Number
%   nFlag       : Flag to include multiplication by N in relative contributions
%
%OUTPUT:
%   value of gEUD
%
%EXAMPLE:
% gEUD = gEUD2Dose(6,13,1);
%
%APA, 07/16/2007
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

global planC stateS
indexS = planC{end};

%Get the x,y,z coords within the passed structure
scanNum                             = getStructureAssociatedScan(structNum);
[rasterSegments, planC, isError]    = getRasterSegments(structNum);
[mask3M, uniqueSlices]              = rasterToMask(rasterSegments, scanNum);
[xScanV, yScanV, zScanV]            = getScanXYZVals(planC{indexS.scan}(scanNum));
[iV,jV,kV]                          = find3d(mask3M);
minIv                               = min(iV);
maxIv                               = max(iV);
minJv                               = min(jV);
maxJv                               = max(jV);
clear iV jV kV

%Get dose's transM
transM = getTransM('dose', doseNum, planC);

%Loop over each structure slice and compute dose
dose3M      = single([]);
doseMref    = single(zeros([length(yScanV) length(xScanV)]));
numPts      = 0;
sumDpowA    = 0;
numSlices = length(uniqueSlices);
hWait = waitbar(0,'Computing dose...');
for i=1:numSlices
    [iV,jV]         = find(mask3M(:,:,i));
    numPts          = numPts + length(iV);
    xV              = xScanV(jV);
    yV              = yScanV(iV);
    zV              = zScanV(uniqueSlices(i))*ones(1,length(xV));
    [xD, yD, zD]    = applyTransM(inv(transM), xV, yV, zV);
    doseV           = (single(getDoseAt(doseNum,xD,yD,zD,planC))).^a;
    sumDpowA        = sumDpowA + sum(doseV);
    doseM           = doseMref;
    indV            = iV + (jV-1)*size(doseM,1);
    doseM(indV)     = doseV;
    dose3M(:,:,i)   = doseM;
    waitbar(i/numSlices,hWait)
end
delete(hWait)

%Obtain gEUD
gEUD = (1/numPts*sumDpowA)^(1/a);

%Apply Bounding box to dose distribution
dose3M = dose3M(minIv:maxIv,minJv:maxJv,:);

%Calculate relative voxel contribution to gEUD
if nFlag == 1
    dose3M = dose3M*gEUD^(1-a);
else
    dose3M = dose3M./sumDpowA*gEUD;
end

%Obtain z-values of dose slices
zVals = zScanV(uniqueSlices);

%Name the dose
fractionGroupID = ['VgEUD_',num2str(a),'_',planC{indexS.structures}(structNum).structureName];

%Create new dose distribution
doseInitS = initializeCERR('dose');
setIndex = length(planC{indexS.dose}) + 1;
doseInitS(1).doseArray = dose3M;
doseInitS(1).imageType='DOSE';
doseInitS(1).caseNumber=1;
doseInitS(1).doseNumber= setIndex;
doseInitS(1).doseType='PHYSICAL';
doseInitS(1).doseUnits='GRAYS';
doseInitS(1).doseScale=1;
doseInitS(1).fractionGroupID= fractionGroupID;
doseInitS(1).orientationOfDose='TRANSVERSE';
doseInitS(1).numberOfDimensions=length(dose3M);
doseInitS(1).sizeOfDimension1=size(dose3M,2);
doseInitS(1).sizeOfDimension2=size(dose3M,1);
doseInitS(1).sizeOfDimension3=size(dose3M,3);
doseInitS(1).assocScanUID = planC{indexS.scan}(scanNum).scanUID;
doseInitS(1).doseUID = createUID('DOSE');
grid2Units = xScanV(2)-xScanV(1);
grid1Units = yScanV(1)-yScanV(2);
doseInitS(1).horizontalGridInterval = grid2Units;
doseInitS(1).verticalGridInterval= - abs(grid1Units);
% doseInitS(1).coord1OFFirstPoint =  xScanV(1);
% doseInitS(1).coord2OFFirstPoint =  yScanV(1);
doseInitS(1).coord1OFFirstPoint =  xScanV(minJv);
doseInitS(1).coord2OFFirstPoint =  yScanV(minIv);
doseInitS(1).zValues = zVals;
planC{indexS.dose} = dissimilarInsert(planC{indexS.dose},doseInitS, setIndex,[]);
stateS.doseToggle = 1;
stateS.doseSetChanged = 1;
stateS.doseSet = setIndex;
CERRRefresh
