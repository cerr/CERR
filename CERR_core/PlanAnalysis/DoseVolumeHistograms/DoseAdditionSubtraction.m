function DoseAdditionSubtraction(firstDose, secondDose,command,doRefresh)
%"DoseSubtraction"
%   Take two doses, subtract the second from the first or adds the two depending on the command. 
%   Command tells the function to 'add' or 'subtract'.Store this as a new planC doseArray.
%   Find the smallest value in the new dose, store this value in planC doses' doseOffset field.
%   Then subtract doseOffset from the new doseArray, storing it as all positive values.
%   flag is used to apply new calculated dose to all or none.
%
%   JRA 5.20.03  - hack to test the effects of direct dose subtraction
%   JRA 5.21.03  - renamed to doseSubtraction, added offset system
%   JRA 5.23.03  - inverted offset
%   JRA 5.26.03  - display the new dose after performing subtraction
%   JRA 10.28.04 - Fixed bug with interpolation size, found thanks to Elinore Wieslander.
%   JRA 11.12.04 - Now correcting dose dimensions if necessary.
%   DK  12.15.05 - Using finterp3NOMESH instead of interp3 to avoid taxing memory
%   DK  12.15.05 - Added dose addition and changed the name from
%   DoseSubtraction to DoseAdditionSubtraction.
%   DK  07.21.06 - UID linking added
%   APA, 03.23.07 - Made compatible with transformations
%
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
%
%Usage:
%   function DoseAdditionSubtraction(firstDoseStruct, firstDoseStruct,command);

global planC;
global stateS;

indexS = planC{end};

if ~exist('doRefresh')
    flag = 1;
else
    flag = 0;
end
% Check for dose Linking
scanSet1 = getAssociatedScan(firstDose.assocScanUID);
scanSet2 = getAssociatedScan(secondDose.assocScanUID);
if scanSet1 == scanSet2
    assocScanUID = firstDose.assocScanUID;
else
    numScans = length(planC{indexS.scan});
    for i = 1: numScans, matchAns{i} = num2str(i); end
    matchAns{end + 1} = 'NA';
    prompt = {['Enter the scanNum between 1 - ' num2str(numScans) ' you want to link dose to "NA" if none:']};
    dlg_title = 'Associated Scan UID';
    num_lines = 1;
    def = {'Enter Scan Index'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    if isempty(answer)
        assocScanUID = '';
    else
        ind = strmatch(answer, matchAns);
        if ind == length(matchAns)
            assocScanUID = '';
        else
            assocScanUID = planC{indexS.scan}(ind).scanUID;
        end
    end
end

[xV1, yV1, zV1] = getDoseXYZVals(firstDose);
[xV2, yV2, zV2] = getDoseXYZVals(secondDose);

if isempty(scanSet1) && ~isempty(scanSet2)
    scanSet1 = inf;
elseif isempty(scanSet2) && ~isempty(scanSet1)
    scanSet2 = -inf;    
end

%check transM for first dose
eyeV = eye(4);
eyeV = eyeV(:);
transM = getTransM(firstDose,planC);
if ~isempty(transM) && ~all(transM(:) == eyeV) && scanSet1 ~= scanSet2

    %Get the corners of the original dataset.
    [xCorn, yCorn, zCorn] = meshgrid([min(xV1) max(xV1)], [min(yV1) max(yV1)], [min(zV1) max(zV1)]);

    %Add ones to the corners so we can apply a transformation matrix.
    corners = [xCorn(:) yCorn(:) zCorn(:) ones(prod(size(xCorn)), 1)];

    %Apply transform to corners, so we know boundary of the slice.
    newCorners = transM * corners';
    newZLims = [min(newCorners(3,:)) max(newCorners(3,:))];
    
    %get transformed z-limits
    zV1 = linspace(newZLims(1),newZLims(2),length(zV1));
    
    %build transformed doseArray
    dA1 = [];
    for i=1:length(zV1)
        [dA1(:,:,i), xV1, yV1] = calcDoseSlice(firstDose, zV1(i), 3, planC);
    end
    
else
    dA1 = getDoseArray(firstDose);    
end
    
%check transM for second dose
transM = getTransM(secondDose,planC);
if ~isempty(transM) && ~all(transM(:) == eyeV) && scanSet1 ~= scanSet2

    %Get the corners of the original dataset.
    [xCorn, yCorn, zCorn] = meshgrid([min(xV2) max(xV2)], [min(yV2) max(yV2)], [min(zV2) max(zV2)]);

    %Add ones to the corners so we can apply a transformation matrix.
    corners = [xCorn(:) yCorn(:) zCorn(:) ones(prod(size(xCorn)), 1)];

    %Apply transform to corners, so we know boundary of the slice.
    newCorners = transM * corners';
    newZLims = [min(newCorners(3,:)) max(newCorners(3,:))];
    
    %get transformed z-limits
    zV2 = linspace(newZLims(1),newZLims(2),length(zV1));
    
    %build transformed doseArray
    dA2 = [];
    for i=1:length(zV1)
        [dA2(:,:,i), xV2, yV2] = calcDoseSlice(secondDose, zV2(i), 3, planC);
    end
    
else
    dA2 = getDoseArray(secondDose);    
end

if isequal(xV1, xV2) && isequal(yV1, yV2) && isequal(zV1, zV2)
    CERRStatusString('Doses defined on identical grids, no interpolation necessary.');
    dA1 = getDoseArray(firstDose);
    dA2 = getDoseArray(secondDose);
    newXVals = xV1;
    newYVals = yV1;
    newZVals = zV1;
else
    CERRStatusString('Doses NOT defined on identical grids, interpolating...');
    
    %Use the smallest sample size in each dimension to speed interpolation.
    newSize = min([size(getDoseArray(firstDose));size(getDoseArray(secondDose))]);
    
    xRange = [min([xV1(:);xV2(:)]) max([xV1(:);xV2(:)])];
    yRange = [min([yV1(:);yV2(:)]) max([yV1(:);yV2(:)])];    
    zRange = [min([zV1(:);zV2(:)]) max([zV1(:);zV2(:)])];    
    
    newXVals = xRange(1):(xRange(2)-xRange(1))/(newSize(2) - 1):xRange(2);
    %Backwards y's as usual.
    newYVals = yRange(2):-(yRange(2)-yRange(1))/(newSize(1) - 1):yRange(1);
    newZVals = zRange(1):(zRange(2)-zRange(1))/(newSize(3) - 1):zRange(2);
%     [newXMesh,newYMesh,newZMesh] = meshgrid(newXVals, newYVals,newZVals);
    CERRStatusString('Doses NOT defined on identical grids, interpolating...first');
    dA1 = finterp3NOMESH(newXVals, newYVals,newZVals, dA1, xV1,yV1,zV1);
%     dA1 = interp3(xV1,yV1,zV1,firstDose.doseArray,newXMesh,newYMesh,newZMesh);
    CERRStatusString('Doses NOT defined on identical grids, interpolating...second');    
    dA2 = finterp3NOMESH(newXVals, newYVals,newZVals, dA2, xV2,yV2,zV2);
%     dA2 = interp3(xV2,yV2,zV2,secondDose.doseArray,newXMesh,newYMesh,newZMesh);
    dA1(isnan(dA1)) = 0;
    dA2(isnan(dA2)) = 0;    
    clear newXMesh newYMesh newZMesh
    CERRStatusString('');    
end

%subtract dose secondDose from dose firstDose
totalDoseNum = length(planC{indexS.dose});
newDoseNum = totalDoseNum + 1;
planC{indexS.dose}(newDoseNum) = firstDose; %copies first dose and uses it as a template
if strcmpi(command,'Subtract')
    planC{indexS.dose}(newDoseNum).doseArray = dA1 - dA2;
    planC{indexS.dose}(newDoseNum).fractionGroupID = [firstDose.fractionGroupID ' - ' secondDose.fractionGroupID];
    planC{indexS.dose}(newDoseNum).doseDescription = 'Dose Subtraction for analysis only';
elseif strcmpi(command,'Add')
    planC{indexS.dose}(newDoseNum).doseArray = dA1 + dA2;
    planC{indexS.dose}(newDoseNum).fractionGroupID = [firstDose.fractionGroupID ' + ' secondDose.fractionGroupID];
    planC{indexS.dose}(newDoseNum).doseDescription = 'Dose Addition for analysis only';
end

planC{indexS.dose}(newDoseNum).doseUID = createUID('dose');
planC{indexS.dose}(newDoseNum).assocScanUID = assocScanUID;
%find minimum value in 3d array, use its negative as the offset
maxDose = max(max(max(planC{indexS.dose}(newDoseNum).doseArray)));
offset = -min(min(min(planC{indexS.dose}(newDoseNum).doseArray)));
if(maxDose == 0 & offset == 0)
    warndlg('Selected Dose Matrices are identical, no subtraction will be performed');
    planC{indexS.dose}(newDoseNum) = [];
    return;
end
planC{indexS.dose}(newDoseNum).doseOffset = offset;
planC{indexS.dose}(newDoseNum).doseArray = planC{indexS.dose}(newDoseNum).doseArray + planC{indexS.dose}(newDoseNum).doseOffset;

%set labels on new dose, overwriting some of the copied labels **Check for more labels that need to be replaced
planC{indexS.dose}(newDoseNum).doseNumber = newDoseNum;

%Remove old caching info.
planC{indexS.dose}(newDoseNum).cachedMask = [];
planC{indexS.dose}(newDoseNum).cachedColor = [];
planC{indexS.dose}(newDoseNum).cachedTime = [];        

%Set coordinates.
planC{indexS.dose}(newDoseNum).sizeOfDimension1 = length(newXVals);
planC{indexS.dose}(newDoseNum).sizeOfDimension2 = length(newYVals);
planC{indexS.dose}(newDoseNum).sizeOfDimension3 = length(newZVals);
planC{indexS.dose}(newDoseNum).horizontalGridInterval = newXVals(2)-newXVals(1);
planC{indexS.dose}(newDoseNum).verticalGridInterval = newYVals(2)-newYVals(1);
planC{indexS.dose}(newDoseNum).depthGridInterval = newZVals(2)-newZVals(1);
planC{indexS.dose}(newDoseNum).coord1OFFirstPoint = newXVals(1);
planC{indexS.dose}(newDoseNum).coord2OFFirstPoint = newYVals(1);
planC{indexS.dose}(newDoseNum).coord3OfFirstPoint = newZVals(1);
planC{indexS.dose}(newDoseNum).zValues = newZVals;

%switch to new dose, with a short pause to let the dialogue clear.
pause(.1);
if flag
    sliceCallBack('selectDose', num2str(newDoseNum));
end
return;
