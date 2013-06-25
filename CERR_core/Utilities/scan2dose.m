function scan2dose(scanNum,assocScanNum,fractionGroupID)
%function scan2dose(scanNum,assocScan,nameString)
%
%This function converts scan scanNum to a dose distribution associated with
%scan assocScanNum.
%
%APA, 05/01/2007
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

% for command line help document
if ~exist('scanNum')& ~exist('assocScanNum')& ~exist('fractionGroupID')
    prompt = {'Enter the scan number';'Enter the associated scan number'; 'Enter the fractionGroupID string'};
    dlg_title = 'Convert scan to dose';
    num_lines = 1;
    def = {'';'';''};
    outPutQst = inputdlg(prompt,dlg_title,num_lines,def);
    if isempty(outPutQst{1}) | isempty(outPutQst{2})| isempty(outPutQst{3})
        warning('Need to enter all the inputs');
        return
    else
        scanNum         = str2num(outPutQst{1});
        assocScanNum    = str2num(outPutQst{2});
        fractionGroupID = outPutQst{3};
    end
end

[xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(scanNum));
zLims = [min(zV) max(zV)];
if isfield(planC{indexS.scan}(scanNum), 'transM') & ~isempty(planC{indexS.scan}(scanNum).transM);
    [rotation, xT, yT, zT] = isrotation(planC{indexS.scan}(scanNum).transM);
else
    rotation=0;
    xT=[0 0];
    yT=[0 0];
    zT=[0 0];
end

xLims = [xV(1) xV(end)];
yLims = [yV(1) yV(end)];
zLims = [zV(1) zV(end)];

if rotation
    %Get the corners of the original scan.
    [xCorn, yCorn, zCorn] = meshgrid(xLims, yLims, zLims);
    %Add ones to the corners so we can apply a transformation matrix.
    corners = [xCorn(:) yCorn(:) zCorn(:) ones(prod(size(xCorn)), 1)];
    %Apply transform to corners, so we know boundary of the slice.
    newCorners = planC{indexS.scan}(scanNum).transM * corners';
    newZLims = [min(newCorners(3,:)) max(newCorners(3,:))];
else
    newZLims = [zLims + zT];
end
zVals = linspace(min(newZLims),max(newZLims),10);

[xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(scanNum));
dose3M = [];
for i=1:length(zVals)
    [slc, sliceXVals, sliceYVals] = getCTOnSlice(scanNum, zVals(i), 3, planC);
    if isempty(slc)
        dose3M(:,:,i) = zeros([length(yV) length(xV)]);
    else
        dose3M(:,:,i) = slc;
        slcXv = sliceXVals;
        slcYv = sliceYVals;
    end
end

% Check for rotation
rotation = 0;
if isfield(planC{indexS.scan}(scanNum), 'transM') && ~isempty(planC{indexS.scan}(scanNum).transM);
    rotation = isrotation(planC{indexS.scan}(scanNum).transM);
end

W = size(dose3M);
setIndex = length(planC{indexS.dose}) + 1;
% Initialize dose
doseInitS = initializeCERR('dose');
if rotation
    doseInitS(1).doseArray = flipdim(dose3M,1);
else
    doseInitS(1).doseArray = dose3M;
end
doseInitS(1).imageType='DOSE';
doseInitS(1).caseNumber=1;
doseInitS(1).doseNumber= setIndex;
doseInitS(1).doseType='PHYSICAL';
doseInitS(1).doseUnits='GRAYS';
doseInitS(1).doseScale=1;
doseInitS(1).fractionGroupID= fractionGroupID;
doseInitS(1).orientationOfDose='TRANSVERSE';
doseInitS(1).numberOfDimensions=length(W);
doseInitS(1).sizeOfDimension1=W(2);
doseInitS(1).sizeOfDimension2=W(1);
doseInitS(1).sizeOfDimension3=W(3);
doseInitS(1).assocScanUID = planC{indexS.scan}(assocScanNum).scanUID;
doseInitS(1).doseUID = createUID('DOSE');
grid2Units = abs(slcXv(2)-slcXv(1));
grid1Units = abs(slcYv(1)-slcYv(2));
doseInitS(1).horizontalGridInterval = grid2Units;
doseInitS(1).verticalGridInterval= - abs(grid1Units);
doseInitS(1).coord1OFFirstPoint =  min(sliceXVals);
doseInitS(1).coord2OFFirstPoint =  max(sliceYVals);
doseInitS(1).zValues = zVals;
planC{indexS.dose} = dissimilarInsert(planC{indexS.dose},doseInitS, setIndex,[]);
stateS.doseToggle = 1;
stateS.doseSetChanged = 1;
stateS.doseSet = setIndex;
CERRRefresh

return;

function [bool, xT, yT, zT] = isrotation(transM);
%"isrotation"
%   Returns true if transM includes rotation.  If it doesn't include
%   rotation, bool=0. xT,yT,zT are the translations in x,y,z
%   respectively.

xT = transM(1,4);
yT = transM(2,4);
zT = transM(3,4);

transM(1:3,4) = 0;
bool = ~isequal(transM, eye(4));
