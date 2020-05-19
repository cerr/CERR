function planC = sumDose(doseNums,wtfactor,lqParamS,assocScan,newDoseName,planC)
%function planC = sumDose(doseNumsV,weightsV,assocScan)
%
%This function creates a new dose distribution by adding up doseNums
%according to factors wtfactor. assocScan is the scan number to associate
%new dose with. newDoseName is the name of new dose.
%
%APA, 12/23/2009
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

wtfactorTmp = wtfactor;
wtfactor = ones(1,max(doseNums));
wtfactor(doseNums) = wtfactorTmp;

indexS = planC{end};
if assocScan > 0
    assocScanUID = planC{indexS.scan}(assocScan).scanUID;
    %Get associated transM
    assocTransM = planC{indexS.scan}(assocScan).transM;
    if isempty(assocTransM)
        assocTransM = eye(4);
    end
else %No Association
    assocScanUID = '';
    assocTransM = eye(4);
end

% doseNums = checkedDoses;

%Get the x,y,z grid for new dose
for i = 1:length(doseNums)
    doseNum = doseNums(i);
    %Get x,y,z values for doseNum
    [xV, yV, zV] = getDoseXYZVals(planC{indexS.dose}(doseNum));
    
    %Get the corners of the original dataset.
    [xCorn, yCorn, zCorn] = meshgrid([min(xV) max(xV)], [min(yV) max(yV)], [min(zV) max(zV)]);
    
    %Add ones to the corners so we can apply a transformation matrix.
    corners = [xCorn(:) yCorn(:) zCorn(:) ones(prod(size(xCorn)), 1)];
    
    %Apply transform to corners, so we know boundary of the slice.
    transM = getTransM(planC{indexS.dose}(doseNum),planC);
    if isempty(transM) || isequal(transM,eye(4))
        [xV,yV,zV] = getDoseXYZVals(planC{indexS.dose}(doseNum));
        xGrid{doseNum} = xV(:)';
        yGrid{doseNum} = yV(:)';
        zGrid{doseNum} = zV(:)';
    else
        newCorners = inv(assocTransM) * transM * corners';
        xGrid{doseNum} = linspace(min(newCorners(1,:)), max(newCorners(1,:)), length(xV));
        yGrid{doseNum} = linspace(max(newCorners(2,:)), min(newCorners(2,:)), length(yV));
        zGrid{doseNum} = linspace(min(newCorners(3,:)), max(newCorners(3,:)), length(zV));
    end
    xRes{doseNum} = length(xV);
    yRes{doseNum} = length(yV);
    zRes{doseNum} = length(zV);
    
    %Get associated scan
    % assocScanV{doseNum} = getAssociatedScan(planC{indexS.dose}(doseNum).assocScanUID);
    assocScanV{doseNum} = getDoseAssociatedScan(doseNum,planC);
end
newXgrid = linspace(min(cell2mat(xGrid)),max(cell2mat(xGrid)),max(cell2mat(xRes)));
newYgrid = linspace(max(cell2mat(yGrid)),min(cell2mat(yGrid)),max(cell2mat(yRes)));
newZgrid = linspace(min(cell2mat(zGrid)),max(cell2mat(zGrid)),max(cell2mat(zRes)));

%Obtain doses with same grid
if isempty(assocTransM)
    assocTransM = eye(4);
end
doseIndC = {};
doseNumsTmp = doseNums;
for iSortAll = 1:length(doseNums)
    iSort = doseNums(iSortAll);
    indRemaining = doseNums;
    indRemaining(iSortAll) = [];
    doseSortM = [iSort];
    if ~ismember(iSort,[doseIndC{:}])
        for jSortAll = 1:length(indRemaining)
            jSort = indRemaining(jSortAll);
            if ~isempty(getTransM('dose',iSort,planC))
                doseITM = inv(assocTransM) * getTransM('dose',iSort,planC);
            else
                doseITM = inv(assocTransM);
            end
            if ~isempty(getTransM('dose',jSort,planC))
                doseJTM = inv(assocTransM) * getTransM('dose',jSort,planC);
            else
                doseJTM = inv(assocTransM);
            end
            if isequal([xRes{iSort},yRes{iSort},zRes{iSort}],[xRes{jSort},yRes{jSort},zRes{jSort}]) && isequal(doseITM,doseJTM)
                doseSortM(end+1) = jSort;
                indJsort = find(doseNumsTmp == jSort);
                doseNumsTmp(indJsort) = [];
            end
        end
    end
    doseIndC{iSort} = doseSortM;
end

doseNums = doseNumsTmp;

%Loop over doses and add over new grid
hWait = waitbar(0,'Summing Dose distributions');
doseSumM = zeros([length(newYgrid),length(newXgrid),length(newZgrid)],'single');
doseEmptyM = zeros([length(newYgrid),length(newXgrid)],'single');

%Assume dose units are same as that of 1st dose
doseUnits = getDoseUnitsStr(doseNums(1),planC);
for i = 1:length(doseNums)
    
    doseNum = doseNums(i);
    
    %Check for transM
    if ~isempty(assocTransM) && ~isequal(assocTransM,eye(4))
        doseTtransM = getTransM('dose',doseNum,planC);
        if isempty(doseTtransM)
            doseTtransM = eye(4);
        end
        inputTM = inv(assocTransM) * doseTtransM;
    else
        inputTM = getTransM('dose',doseNum,planC);
        if isempty(inputTM)
            inputTM = eye(4);
        end
    end
    
    SOPInstanceUIDv = {planC{indexS.beams}.SOPInstanceUID};
    if ~isempty(lqParamS)
        paramS.Tk.val = inf;         %Kick-off time of repopulation (days)
        paramS.Tp.val = NaN;        %Potential tumor doubling time (days)
        paramS.alpha.val = NaN;
        paramS.abRatio.val = lqParamS.abRatio; %10;  %alpha/beta
        paramS.stdFractionSize = lqParamS.stdFractionSize; % 2;
    end
    
    %Get the summation for this grid
    doseCombinedM = [];
    for iDoseAll = 1:length(doseIndC{doseNum})
        iDose = doseIndC{doseNum}(iDoseAll);
        doseUnits2 = getDoseUnitsStr(iDose,planC);
        if strcmpi(doseUnits, 'Gy') && strcmpi(doseUnits2, 'cGy')
            multFact = 0.01;
        elseif strcmpi(doseUnits, 'cGy') && strcmpi(doseUnits2, 'Gy')
            multFact = 100;
        else
            multFact = 1;
        end
        doseOffset = planC{indexS.dose}(iDose).doseOffset;
        if isempty(doseOffset)
            doseOffset = 0;
        end
        doseArray = single(getDoseArray(planC{indexS.dose}(iDose)) - doseOffset);
        
        % Apply BED/EQD2 correction
        if ~isempty(lqParamS)
            ReferencedSOPInstanceUID = planC{indexS.dose}(iDose)...
                .DICOMHeaders.ReferencedRTPlanSequence.Item_1.ReferencedSOPInstanceUID;
            planNum = find(strcmpi(ReferencedSOPInstanceUID,SOPInstanceUIDv));
            paramS.numFractions.val = planC{indexS.beams}(planNum(1)).FractionGroupSequence...
                .Item_1.NumberOfFractionsPlanned;
            paramS.numFractions.val = double(paramS.numFractions.val);
            paramS.frxSize.val = doseArray / paramS.numFractions.val;
            doseArray = calc_BED(paramS) / (1+paramS.stdFractionSize/paramS.abRatio.val);
        end
        
        if ~isempty(doseCombinedM)
            doseCombinedM = doseCombinedM + multFact * wtfactor(iDose) * doseArray;
        else
            doseCombinedM = multFact * wtfactor(iDose) * doseArray;
        end
    end
    
    %Check if this dose is on same grid as the new one
    %if isequal(xGrid{doseNum},newXgrid) && isequal(yGrid{doseNum},newYgrid) && isequal(zGrid{doseNum},newZgrid)
    chkLength = length(xGrid{doseNum})==length(newXgrid) && length(yGrid{doseNum})==length(newYgrid) && length(zGrid{doseNum})==length(newZgrid);
    if sum(sum((inputTM-eye(4)).^2)) < 1e-3 && chkLength && max(abs(xGrid{doseNum}-newXgrid)) < 1e-3 && max(abs(yGrid{doseNum}-newYgrid)) < 1e-3 && max(abs(zGrid{doseNum}-newZgrid)) < 1e-3
        
        doseSumM = doseSumM + doseCombinedM;
        waitbar((i-1)/length(doseNums),hWait,['Calculating contribution from Dose ', num2str(doseNum)])
        
    else %interpolation required
        
        %Transform this dose
        doseTmpM = [];
        
        for slcNum=1:length(newZgrid)
            [xV, yV, zV] = getDoseXYZVals(planC{indexS.dose}(doseNum));
            doseTmp = slice3DVol(doseCombinedM, xV, yV, zV, newZgrid(slcNum), 3, 'linear', inputTM, [], newXgrid, newYgrid);
            if isempty(doseTmp)
                doseTmpM(:,:,slcNum) = doseEmptyM;
            else
                doseTmpM(:,:,slcNum) = doseTmp;
            end
            waitbar((i-1)/length(doseNums) + (slcNum-1)/length(newZgrid)/length(doseNums) ,hWait,['Calculating contribution from Dose ', num2str(doseNum)])
        end
        
        doseSumM = doseSumM + doseTmpM;
        
    end
    
end

delete(hWait)

%Create new dose distribution
newDoseNum = length(planC{indexS.dose}) + 1;
planC{indexS.dose}(newDoseNum).doseArray = doseSumM;
clear doseSumM
planC{indexS.dose}(newDoseNum).doseUID = createUID('dose');
planC{indexS.dose}(newDoseNum).assocScanUID = assocScanUID;

%Find minimum value in 3d array, use its negative as the offset
maxDose = max(max(max(planC{indexS.dose}(newDoseNum).doseArray)));
offset = -min(min(min(planC{indexS.dose}(newDoseNum).doseArray)));
if offset > 0
    planC{indexS.dose}(newDoseNum).doseOffset = offset;
    planC{indexS.dose}(newDoseNum).doseArray = planC{indexS.dose}(newDoseNum).doseArray + offset;
end

%set labels on new dose, overwriting some of the copied labels **Check for more labels that need to be replaced
planC{indexS.dose}(newDoseNum).doseNumber = newDoseNum;
planC{indexS.dose}(newDoseNum).fractionGroupID = newDoseName;

%Remove old caching info.
planC{indexS.dose}(newDoseNum).cachedMask = [];
planC{indexS.dose}(newDoseNum).cachedColor = [];
planC{indexS.dose}(newDoseNum).cachedTime = [];

%Set coordinates.
planC{indexS.dose}(newDoseNum).sizeOfDimension1 = length(newXgrid);
planC{indexS.dose}(newDoseNum).sizeOfDimension2 = length(newYgrid);
planC{indexS.dose}(newDoseNum).sizeOfDimension3 = length(newZgrid);
planC{indexS.dose}(newDoseNum).horizontalGridInterval = newXgrid(2)-newXgrid(1);
planC{indexS.dose}(newDoseNum).verticalGridInterval = newYgrid(2)-newYgrid(1);
planC{indexS.dose}(newDoseNum).depthGridInterval = newZgrid(2)-newZgrid(1);
planC{indexS.dose}(newDoseNum).coord1OFFirstPoint = newXgrid(1);
planC{indexS.dose}(newDoseNum).coord2OFFirstPoint = newYgrid(1);
planC{indexS.dose}(newDoseNum).coord3OfFirstPoint = newZgrid(1);
planC{indexS.dose}(newDoseNum).zValues = newZgrid;
planC{indexS.dose}(newDoseNum).doseUnits = doseUnits;

