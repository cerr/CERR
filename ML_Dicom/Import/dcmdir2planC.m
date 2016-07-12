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

for i = 1:length(cellNames)
    %Populate each field in the planC.
    disp([' Reading ' cellNames{i}  ' ... ']);
    cellData = populate_planC_field(cellNames{i}, dcmdir_PATIENT);
    
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

% process NM scans
for scanNum = 1:length(planC{indexS.scan})
    if strcmpi(planC{indexS.scan}(scanNum).scanInfo(1).imageType, 'NM')
        if planC{indexS.scan}(scanNum).scanInfo(1).DICOMHeaders.SpacingBetweenSlices < 0
            planC{indexS.scan}(scanNum).scanArray = flipdim(planC{indexS.scan}(scanNum).scanArray,3);
        end
    end
end

% process scan zValues for MR, by Deshan Yang, 3/2/2010
try
    for scanNum = 1:length(planC{indexS.scan})
        if strcmpi(planC{indexS.scan}(scanNum).scanInfo(1).imageType, 'MR')
            %%%%% CHANGED - AI 3/3/16 %%%%%%%
            imgNumverV = [planC{indexS.scan}(scanNum).scanInfo.imageNumber];
            if ~isempty(imgNumverV)
                [~,sortIdxV] = sort(imgNumverV);
            else
                sortIdxV = 1:length(planC{indexS.scan}(scanNum).scanInfo);
            end
            % First, set the scan to a fake coordinate system
            info1 = planC{indexS.scan}(scanNum).scanInfo(sortIdxV(1));
            info2 = planC{indexS.scan}(scanNum).scanInfo(sortIdxV(2));
            pos1 = [info1.xOffset info1.yOffset info1.zValue];
            pos2 = [info2.xOffset info2.yOffset info2.zValue];
            deltaPos = pos2-pos1;
            direction = sign(deltaPos(3));
            if ~direction
                direction = 1;
            end
            slice_distance = sqrt(sum(deltaPos.^2));
            for i=1:length(planC{indexS.scan}(scanNum).scanInfo)
                planC{indexS.scan}(scanNum).scanInfo(sortIdxV(i)).zValue = pos1(3)+ direction*(i-1)*slice_distance;
            end
            
            %Reorder by z-value (ascending)
            [~,zOrderV] = sort([planC{indexS.scan}(scanNum).scanInfo.zValue]);
            planC{indexS.scan}(scanNum).scanInfo = planC{indexS.scan}(scanNum).scanInfo(zOrderV);
            planC{indexS.scan}.scanArray = planC{indexS.scan}.scanArray(:,:,zOrderV);
            
            %%%%%%%%%%%%%%%%
            info1b = info1.DICOMHeaders;
            info2b = info2.DICOMHeaders;
            pos1b = info1b.ImagePositionPatient;
            pos2b = info2b.ImagePositionPatient;
            deltaPosb = pos2b-pos1b;
            
            positionMatrix = [reshape(info1b.ImageOrientationPatient,[3 2])*diag(info1b.PixelSpacing) [deltaPosb(1) pos1b(1);deltaPosb(2) pos1b(2); deltaPosb(3) pos1b(3)]];
            positionMatrix = positionMatrix / 10; % mm to cm
            positionMatrix = [positionMatrix; 0 0 0 1];
            
            positionMatrixInv = inv(positionMatrix);
            planC{indexS.scan}.Image2PhysicalTransM = positionMatrix;
            
            [xs,ys,zs]=getScanXYZVals(planC{indexS.scan});
            dx = xs(2)-xs(1);
            dy = ys(2)-ys(1);
            nx = length(xs);
            ny = length(ys);
            virPosMtx = [dx 0 0 xs(1);0 dy 0 ys(1); 0 0 slice_distance zs(1); 0 0 0 1];
            planC{indexS.scan}(scanNum).Image2VirtualPhysicalTransM = virPosMtx;            
            
%             % Just update structures saaociated with scanNum (to do)            
%             N = length(planC{indexS.structures});
%             if N>0
%                 % Now, translate the contour points to the same coordinate system
%                 for nvoi = 1:N
%                     % for each structure
%                     M = length(planC{indexS.structures}(nvoi).contour);
%                     for sliceno = 1:M
%                         % for each contour
%                         points = planC{indexS.structures}(nvoi).contour(sliceno).segments;
%                         % y and z are inverted, now get the original data back
%                         points(:,2:3) = -points(:,2:3);
%                         
%                         if ~isempty(points)
%                             tempa = [points ones(size(points,1),1)];
%                             tempa = positionMatrixInv*tempa';
%                             tempa(3,:) = round(tempa(3,:)); % round the voi points onto the slice
%                             
%                             tempb = virPosMtx*tempa;
%                             tempb = tempb';
%                             
%                             planC{indexS.structures}(nvoi).contour(sliceno).segments = tempb(:,1:3);
%                         end
%                                                 
%                     end
%                 end
%             end
            
            % Just update doses saaociated with scanNum (to do)
            N = length(planC{indexS.dose});
            if N > 0
                % Now, translate the coordinates for dose
                for doseno = 1:N
                    dose = planC{indexS.dose}(doseno);
                    if ~isfield(dose,'DICOMHeaders')
                        continue;
                    end
                    
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
                    
                    dose.zValues = vecsout(3,:)';
                    
                    planC{indexS.dose}(doseno) = dose;
                end
            end
            
        end
    end
catch
end
% end of changes by Deshan Yang

% Check uniqueness of scanUIDs
assocScanUIDc = {planC{indexS.structures}.assocScanUID};
[uidC,iA,iC] = unique({planC{indexS.scan}.scanUID});
if length(iA) < length(planC{indexS.scan})
    for scanNum = 1:length(planC{indexS.scan})
        assocStrV = strcmpi(assocScanUIDc,planC{indexS.scan}(scanNum).scanUID);
        planC{indexS.scan}(scanNum).scanUID = ...
            [planC{indexS.scan}(scanNum).scanUID, '.', num2str(scanNum)];
        [planC{indexS.structures}(assocStrV).assocScanUID] = ...
            deal(planC{indexS.scan}(scanNum).scanUID);
    end
end


% Create a Dummy Scan if no scan is available
if isempty(planC{indexS.scan})
    planC = createDummyScan(planC);
    %associate all structures to the first scanset.
    strNum = length(planC{indexS.structures});
    for i=1:strNum
        planC{indexS.structures}(i).assocScanUID = planC{indexS.scan}(1).scanUID;
    end
end

scanNum = length(planC{indexS.scan});
if (scanNum>1)
    if exist('mergeScansFlag','var')
        button = mergeScansFlag;
    else
        button = questdlg(['There are ' num2str(scanNum) 'scans, do you want to put them together?'],'Merge CT in 4D Series', ...
            'Yes', 'No', 'No');
    end
    switch lower(button)
        case 'yes'
            %sort the all scan series
            % 4/21/16 Updated to handle single-slice scan sets
            if numel(planC{indexS.scan}(1).scanInfo) > 1
                if (planC{indexS.scan}(1).scanInfo(2).zValue > planC{indexS.scan}(1).scanInfo(1).zValue)
                    sortingMode = 'ascend';
                else
                    sortingMode = 'descend';
                end
            else  %Sort single-slice scan sets by ascending order of z-value by default
                sortingMode = 'ascend';
            end
            
            zV = zeros(1, scanNum);
            for i=1:scanNum
                zV(i) = planC{3}(i).scanInfo(1).zValue;
            end
            [B,Ind] = sort(zV, 2, sortingMode);
            
            %add all scans to the first one.
            scanArray = []; scanInfo = [];
            for i=1:scanNum
                scanArray = cat(3, scanArray, planC{3}(Ind(i)).scanArray);
                scanInfo = cat(2, scanInfo, planC{3}(Ind(i)).scanInfo);
            end
            
            %delete all other scans
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
    planC{indexS.structures}(i) = sortStructures(planC{indexS.structures}(i), planC);
end

%TEMPORARY.
% for i=1:length(planC{indexS.dose})
%    planC{indexS.dose}(i).assocScanUID = planC{indexS.scan}(1).scanUID;
% end

planC = getRasterSegs(planC);
planC = setUniformizedData(planC);
