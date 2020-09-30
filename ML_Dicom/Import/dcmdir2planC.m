function planC = dcmdir2planC(dcmdir,mergeScansFlag)
%"dcmdir2planC"
%   Convert a dcmdir object representing a patient into a planC.
%
%JRA 06/15/06
%YWU 03/01/08
%
%Usage:
%   planC = dcmdir2planC(dcmdir,mergeScansFlag);
%   dcmdir: directory containing DICOM files.
%   mergeScansFlag: Optional argument to merge scans as a 4-D series. Acceptable values are 'Yes' or 'No'.
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

planInitC = initializeCERR;

indexS = planInitC{end};

%Assume a single patient for the moment
dcmdir_PATIENT = dcmdir; %wy .PATIENT{1};

%Get the names of all cells in planC.
cellNames = fields(indexS);

%Read CERROptions.json to get import flags
pathStr = getCERRPath;
optName = fullfile(pathStr,'CERROptions.json');
optS    = opts4Exe(optName);

for i = 1:length(cellNames)
    %Populate each field in the planC.
    disp([' Reading ' cellNames{i}  ' ... ']);
    cellData = populate_planC_field(cellNames{i}, dcmdir_PATIENT, optS);
    
    if ~isempty(cellData)
        planInitC{indexS.(cellNames{i})} = cellData;
    end
end

planC = planInitC;
planC = guessPlanUID(planC,1,1);
%After initial import, run any functions to address issues where
%subfunctions had insufficent data to make relationship determinations.

%process doseOffset
for doseNum = 1:length(planC{indexS.dose})
    if min(planC{indexS.dose}(doseNum).doseArray(:)) < 0
        planC{indexS.dose}(doseNum).doseOffset = -min(planC{indexS.dose}(doseNum).doseArray(:));
        planC{indexS.dose}(doseNum).doseArray = planC{indexS.dose}(doseNum).doseArray + planC{indexS.dose}(doseNum).doseOffset;
    else
        planC{indexS.dose}(doseNum).doseOffset = [];
    end
end

% process scan zValues for US
try
    for scanNum = 1:length(planC{indexS.scan})
        if isempty(planC{indexS.scan}(scanNum).scanInfo(1).zValue)
            if strcmpi(planC{indexS.scan}(scanNum).scanInfo(1).imageType, 'US')
                if ~isempty(planC{8})
                    zValues = planC{8}.zValues;
                    for i=1:length(planC{indexS.scan}.scanInfo)
                        planC{indexS.scan}(scanNum).scanInfo(i).zValue = zValues(i);
                    end
                end
            end
        end
    end
catch
end

% Convert to PET SUV
for scanNum = 1:length(planC{indexS.scan})
    modality = planC{indexS.scan}(scanNum).scanInfo(1).imageType;
    if strcmpi(modality,'PT') || strcmpi(modality,'PET')
        imageUnits = planC{indexS.scan}(scanNum).scanInfo(1).imageUnits;
        if ~strcmpi(imageUnits,'GML')
            if isfield(optS,'convert_PET_to_SUV') && optS.convert_PET_to_SUV
                suvType = optS.suvType;
                planC = calc_suv(scanNum,planC,suvType);
            end
        end
    end
end

% process NM scans
for scanNum = 1:length(planC{indexS.scan})
    if strcmpi(planC{indexS.scan}(scanNum).scanInfo(1).imageType, 'NM')
        if planC{indexS.scan}(scanNum).scanInfo(1).DICOMHeaders.SpacingBetweenSlices < 0
            planC{indexS.scan}(scanNum).scanArray = flipdim(planC{indexS.scan}(scanNum).scanArray,3);
        end
    end
end

% process scan coordinates for oblique MR. (based on code by Deshan Yang,
% 3/2/2010)
numStructs = length(planC{indexS.structures});
assocScanV = getStructureAssociatedScan(1:numStructs, planC);
% assocScanV = 1; % temporary, until the issue with DCE/DWI volume split is
% resolved.

% Assign scan type
% Check for scanType field and populate it with Series description
for scanNum = 1:length(planC{indexS.scan})
    if isempty(planC{indexS.scan}(scanNum).scanType) && ...
            isfield(planC{indexS.scan}(scanNum).scanInfo(1),'DICOMHeaders') && ...
            isfield(planC{indexS.scan}(scanNum).scanInfo(1).DICOMHeaders,'SeriesDescription')
        planC{indexS.scan}(scanNum).scanType = ...
            planC{indexS.scan}(scanNum).scanInfo(1).DICOMHeaders.SeriesDescription;
    end
end

% Split multi-frame MRIs by b-value
imageTypeC = arrayfun(@(x)x.scanInfo(1).imageType, planC{indexS.scan}, 'un',0);
mrIdxV = find(ismember(imageTypeC,'MR'));
splitScanNumV = [];
if ~isempty(mrIdxV)
    newScanC = {};
    for m = 1:length(mrIdxV)
        scanNum = mrIdxV(m);
        scanS = planC{indexS.scan}(scanNum);
        bValV = [scanS.scanInfo(:).bValue];
        temporalPositionIndexV = [scanS.scanInfo(:).temporalPositionIndex];
        uniqueBvalV = unique(bValV);
        uniqueTemporalPosIndV = unique(temporalPositionIndexV);
        splitScanS = scanS;
        if length(uniqueBvalV)>1 && isempty(uniqueTemporalPosIndV)
            splitScanNumV = [splitScanNumV,scanNum];
            for n = 1:length(uniqueBvalV)
                groupIdxV = bValV==uniqueBvalV(n);
                splitScanS(n) = scanS;
                splitScanInfoS = scanS.scanInfo(groupIdxV);
                splitScanArray = scanS.scanArray(:,:,groupIdxV);
                splitScanS(n).scanInfo = splitScanInfoS;
                splitScanS(n).scanArray = splitScanArray;
                splitScanS(n).scanUID = createUID('scan');
                splitScanS(n).scanType = [scanS.scanType,' (bVal=',...
                    num2str(uniqueBvalV(n)),')'];
            end
            count = length(splitScanNumV);
            newScanC{count} = splitScanS;
        end
        if length(uniqueTemporalPosIndV)>1 && isempty(uniqueBvalV)
            splitScanNumV = [splitScanNumV,scanNum];
            for n = 1:length(uniqueTemporalPosIndV)
                groupIdxV = temporalPositionIndexV==uniqueTemporalPosIndV(n);
                splitScanS(n) = scanS;
                splitScanInfoS = scanS.scanInfo(groupIdxV);
                splitScanArray = scanS.scanArray(:,:,groupIdxV);
                splitScanS(n).scanInfo = splitScanInfoS;
                splitScanS(n).scanArray = splitScanArray;
                splitScanS(n).scanUID = createUID('scan');
                splitScanS(n).scanType = [scanS.scanType,' (temporalPos=',...
                    num2str(uniqueTemporalPosIndV(n)),')'];
            end
            count = length(splitScanNumV);
            newScanC{count} = splitScanS;            
        end        
    end
    
    for m = 1:length(newScanC)
        
        newScansS = newScanC{m};
        origScanNum = splitScanNumV(m);
        planC = deleteScan(planC,origScanNum);
        for iScan = 1:length(newScansS)
            planC{indexS.scan} = dissimilarInsert(planC{indexS.scan}, newScansS(iScan));
        end
        
    end
end


% Tolerance to determine oblique scan (think about passing it as a
% parameter in future)
obliqTol = 1e-3;
numScans = length(planC{indexS.scan});
isObliqScanV = ones(1,numScans);

for scanNum = 1:numScans
    
    % Check for Mammogram images
    imageType = planC{indexS.scan}(scanNum).scanInfo(1).imageType;
    if ismember(imageType,{'MG','SM'})
        continue
    end
    
    ImageOrientationPatientV = planC{indexS.scan}(scanNum).scanInfo(1).imageOrientationPatient;
    
    % Check for obliqueness
    if max(abs((abs(ImageOrientationPatientV) - [1 0 0 0 1 0]'))) <= obliqTol
        isObliqScanV(scanNum) = 0;
        continue;
    end
        
    % Compute slice normal
    sliceNormV = ImageOrientationPatientV([2 3 1]) .* ImageOrientationPatientV([6 4 5]) ...
        - ImageOrientationPatientV([3 1 2]) .* ImageOrientationPatientV([5 6 4]);
    
    % Calculate the distance of ‘ImagePositionPatient’ along the slice direction cosine
    numSlcs = length(planC{indexS.scan}(scanNum).scanInfo);
    distV = zeros(1,numSlcs);
    for slcNum = 1:numSlcs
        ipp = planC{indexS.scan}(scanNum).scanInfo(slcNum).imagePositionPatient;            
        distV(slcNum) = sum(sliceNormV .* ipp);
    end
    
    info1S = planC{indexS.scan}(scanNum).scanInfo(end);
    info2S = planC{indexS.scan}(scanNum).scanInfo(end-1);
    
    % sort z-values in ascending order since z increases from head
    % to feet in CERR
    [zV,zOrderV] = sort(distV);
    slice_distance = zV(2) - zV(1);
    for i=1:length(planC{indexS.scan}(scanNum).scanInfo)
        planC{indexS.scan}(scanNum).scanInfo(i).zValue = zV(i) / 10;
    end
    pos1V = info1S.imagePositionPatient/10; %cm
    pos2V = info2S.imagePositionPatient/10; %cm
    deltaPosV = pos2V-pos1V;
    pixelSpacing = [info1S.grid2Units, info1S.grid1Units];
    
    %Pt coordinate to DICOM image coordinate mapping 
    %Based on ref: https://nipy.org/nibabel/dicom/dicom_orientation.html
    positionMatrix = [reshape(ImageOrientationPatientV,[3 2])*diag(pixelSpacing)...
        [deltaPosV(1) pos1V(1); deltaPosV(2) pos1V(2); deltaPosV(3) pos1V(3)]];
    positionMatrix = [positionMatrix; 0 0 0 1];
    
    positionMatrixInv = inv(positionMatrix);
    planC{indexS.scan}(scanNum).Image2PhysicalTransM = positionMatrix;
    
    [xs,ys,zs] = getScanXYZVals(planC{indexS.scan}(scanNum));
    dx = xs(2)-xs(1);
    dy = ys(2)-ys(1);
    virPosMtx = [dx 0 0 xs(1);0 dy 0 ys(1); 0 0 slice_distance zs(1); 0 0 0 1];
    planC{indexS.scan}(scanNum).Image2VirtualPhysicalTransM = virPosMtx;
    
    % Find structures associated with scanNum and update
    
    % Update the structures saaociated with scanNum (to do)
    structsToUpdateV = find(assocScanV == scanNum);
    %if N>0
    % Now, translate the contour points to the same coordinate system
    for nvoi = structsToUpdateV
        
        % for each structure
        M = length(planC{indexS.structures}(nvoi).contour);
        for segnum = 1:M
            
            % for each segment
            points = planC{indexS.structures}(nvoi).contour(segnum).segments;
            % Undo inversion of z coord inverted for oblique scans 
            % (in populate_planC_structures_field.m)
            points(:,3) = -points(:,3);
            
            if ~isempty(points)
                tempa = [points ones(size(points,1),1)];
                tempa = positionMatrixInv*tempa';
                tempa(3,:) = round(tempa(3,:)); % round the voi points onto the slice
                
                tempb = virPosMtx*tempa;
                tempb = tempb';
                
                planC{indexS.structures}(nvoi).contour(segnum).segments = tempb(:,1:3);
            end
            
        end
    end
    %end
    
    % Update the doses associated with scanNum (to do)
    N = length(planC{indexS.dose});
    if N > 0
        % Now, translate the coordinates for dose
        for doseno = 1:N
            dose = planC{indexS.dose}(doseno);
            if ~isfield(dose,'DICOMHeaders')
                continue;
            end
            
            % ======== TO DO: update for use without DICOMHeaders
            info = dose.DICOMHeaders;
            
            vec1 = info.ImageOrientationPatient(1:3);
            vec2 = info.ImageOrientationPatient(4:6);
            vec3 = cross(vec1,vec2);
            vec3 = vec3 * (info.GridFrameOffsetVector(2)-info.GridFrameOffsetVector(1));
            pos1 = info.ImagePositionPatient;
            
            % positionMatrix translate voxel indexes to physical
            % coordinates
            dosePositionMatrix = [reshape(info.ImageOrientationPatient,[3 2])*diag(info.PixelSpacing) [vec3(1) pos1(1);vec3(2) pos1(2); vec3(3) pos1(3)]];
            dosePositionMatrix = [dosePositionMatrix; 0 0 0 1];
            
            dosedim = size(dose.doseArray);
            
            % Need to figure out coord1OFFirstPoint,
            % coord2OFFirstPoint, horizontalGridInterval,
            % verticalGridInterval and zValues
            
            % 				xOffset = iPP(1) + (pixspac(1) * (nCols - 1) / 2);
            % 				yOffset = iPP(2) + (pixspac(2) * (nRows - 1) / 2);
            
            vecs = [0 0 0 1; 1 1 0 1; (dosedim(2)-1)/2 (dosedim(1)-1)/2 0 1];
            vecsout = (dosePositionMatrix*vecs'); % to physical coordinates
            vecsout(1:3,:) = vecsout(1:3,:)/10;
            vecsout = inv(positionMatrix) * vecsout;  % to MR image index (not dose voxel index)
            vecsout = virPosMtx * vecsout; % to the virtual coordinates
            
            % 				dose.coord1OFFirstPoint = vecsout(1,3);
            % 				dose.coord2OFFirstPoint = vecsout(2,3);
            dose.coord1OFFirstPoint = vecsout(1,1);
            dose.coord2OFFirstPoint = vecsout(2,1);
            dose.horizontalGridInterval = vecsout(1,2) - vecsout(1,1);
            dose.verticalGridInterval = vecsout(2,2) - vecsout(2,1);
            
            vecs = [zeros(2,dosedim(3));0:(dosedim(3)-1);ones(1,dosedim(3))];
            vecsout = (dosePositionMatrix*vecs); % to physical coordinates
            vecsout(1:3,:) = vecsout(1:3,:)/10;
            vecsout = inv(positionMatrix) * vecsout;  % to MR image index (not dose voxel index)
            vecsout = virPosMtx * vecsout; % to the virtual coordinates
            
            zValuesV = vecsout(3,:)'/10;
            [zdoseV,zOrderV] = sort(zValuesV);
            dose.zValues = zdoseV;
            %[zdoseV,zOrderV] = sort(dose.zValues);
            %dose.zValues = zdoseV;
            
            % Flip doseArray similar to the scanArray
            % Flip scan since DICOM and CERR's z-convention is opposite.
            % Hence sort according to descending z-values.
            %[~,zOrderV] = sort(dose.zValues,'descend'); % flip dose
            dose.doseArray = dose.doseArray(:,:,flip(zOrderV));
            
            planC{indexS.dose}(doseno) = dose;
        end
    end
        
end % end of scan loop
    

% Check uniqueness of scanUIDs
assocStrScanUIDc = {planC{indexS.structures}.assocScanUID};
assocDoseScanUIDc = {planC{indexS.dose}.assocScanUID};
[uidC,iA,iC] = unique({planC{indexS.scan}.scanUID});
if length(iA) < length(planC{indexS.scan})
    allScansV = 1:numScans;
    repeatUidV = allScansV(~ismember(allScansV,iA));
    for iScan = 1:length(repeatUidV) %length(planC{indexS.scan})
        scanNum = repeatUidV(iScan);
        assocStrV = strcmpi(assocStrScanUIDc,planC{indexS.scan}(scanNum).scanUID);
        assocDoseV = strcmpi(assocDoseScanUIDc,planC{indexS.scan}(scanNum).scanUID);
        planC{indexS.scan}(scanNum).scanUID = ...
            [planC{indexS.scan}(scanNum).scanUID, '.', num2str(iScan)];
        [planC{indexS.structures}(assocStrV).assocScanUID] = ...
            deal(planC{indexS.scan}(scanNum).scanUID);
        [planC{indexS.dose}(assocDoseV).assocScanUID] = ...
            deal(planC{indexS.scan}(scanNum).scanUID);
    end
end


% Create a Dummy Scan if no scan is available
if isempty(planC{indexS.scan})
    planC = createDummyScan(planC);
    isObliqScanV(1) = 0; % non-oblique "dummy" scan
    %associate all structures to the first scanset.
    numStructs = length(planC{indexS.structures});
    for i=1:numStructs
        planC{indexS.structures}(i).assocScanUID = planC{indexS.scan}(1).scanUID;
    end
    %associate all doses to the first scanset.
    numDoses = length(planC{indexS.dose});
    for i=1:numDoses
        planC{indexS.dose}(i).assocScanUID = planC{indexS.scan}(1).scanUID;
    end
end

scanNum = length(planC{indexS.scan});
if (scanNum>1)
    if exist('mergeScansFlag','var') && ~isempty(mergeScansFlag)
        button = mergeScansFlag;
    else
        button = questdlg(['There are ' num2str(scanNum) ' scan volumes. Do you want to append them?'],'Merge CT in 4D Series', ...
            'Yes', 'No', 'No');
    end
    switch lower(button)
        case 'yes'
            % Merge according to zValue
            zV = [];
            scanNumV = [];
            slcNumV = [];
            for i=1:scanNum
                scanInfoS = planC{indexS.scan}(i).scanInfo;
                for iSlc = 1:length(scanInfoS)
                    zV(end+1) = scanInfoS(iSlc).zValue;
                    scanNumV(end+1) = i;
                    slcNumV(end+1) = iSlc;
                end                
            end
            [zSortV,indSortV] = sort(zV,'ascend');
            scanNumSortV = scanNumV(indSortV);
            slcNumSortV = slcNumV(indSortV);
            
            % build scanArray and scnInfo from sorted z values.
            scanArray = []; scanInfo = struct();
            for i=1:length(zSortV)
                scanIndex = scanNumSortV(i);
                slcIndex = slcNumSortV(i);
                scanArray(:,:,i) = planC{indexS.scan}(scanIndex).scanArray(:,:,slcIndex);
                scanInfo = dissimilarInsert(scanInfo, planC{indexS.scan}(scanIndex).scanInfo(slcIndex),i);
            end

            %add all scans to the first one. Delete the rest.
            planC{indexS.scan} = planC{indexS.scan}(1);
            planC{indexS.scan}.scanArray = scanArray;
            planC{indexS.scan}.scanInfo = scanInfo;
            
            %associate all structures to the first scanset.
            strNum = length(planC{indexS.structures});
            for i=1:strNum
                planC{indexS.structures}(i).assocScanUID = planC{indexS.scan}(1).scanUID;
            end
            
        case 'no'
            
    end
end

%Sort contours for each structure to match the associated scan.
for i=1:length(planC{indexS.structures})
    planC{indexS.structures}(i) = sortStructures(planC{indexS.structures}(i),...
        isObliqScanV, planC);
end

planC = getRasterSegs(planC);

%---------Create uniformized datasets----------------%
str = optS.createUniformizedDataset;
if strcmpi(str,'yes') && ...
        strcmpi(optS.loadCT,'yes') && ...
        isfield(planC{indexS.scan}, 'scanInfo') %can only make uniformized dataset if scan exists
    planC = setUniformizedData(planC);
end

