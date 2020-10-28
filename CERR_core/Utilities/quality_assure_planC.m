function planC = quality_assure_planC(fileName, planC, forceSaveFlag)
%function planC = quality_assure_planC(fileName, planC, forceSaveFlag)
%
% This function quality assures planC.
%
%APA, 04/07/2011

if ~exist('planC','var')
    global planC
end
if ~exist('forceSaveFlag','var')
    forceSaveFlag = 0;
end

global stateS
indexS = planC{end};

% Quality Assurance
bug_found = 0;

% Detect and Fix incorrect rasterSegments
if length(planC{indexS.header})>0 && isfield(planC{indexS.header}(1), 'lastSavedInVer')
    lastSavedInVer = planC{indexS.header}(1).lastSavedInVer;
else
    lastSavedInVer = '';
end

if ~isempty(str2double(lastSavedInVer)) && (isempty(lastSavedInVer) || str2double(lastSavedInVer) < 4.1) && ~isempty(planC{indexS.structures})
    planC = reRasterAndUniformize(planC);
    bug_found = 1;
end


% %Check for mesh representation and load meshes into memory
% currDir = cd;
% meshDir = fileparts(which('libMeshContour.dll'));
% cd(meshDir)
% for strNum = 1:length(planC{indexS.structures})
%     if isfield(planC{indexS.structures}(strNum),'meshRep') && ~isempty(planC{indexS.structures}(strNum).meshRep) && planC{indexS.structures}(strNum).meshRep
%         try
%             calllib('libMeshContour','loadSurface',planC{indexS.structures}(strNum).strUID,planC{indexS.structures}(strNum).meshS)
%         catch
%             planC{indexS.structures}(strNum).meshRep    = 0;
%             planC{indexS.structures}(strNum).meshS      = [];
%         end
%     end
% end
% cd(currDir)

if ~isfield(stateS,'optS')
    stateS.optS = opts4Exe([getCERRPath,'CERROptions.json']);
end

%Check color assignment for displaying structures
[assocScanV,relStrNumV] = getStructureAssociatedScan(1:length(planC{indexS.structures}),planC);
for scanNum = 1:length(planC{indexS.scan})
    scanIndV = find(assocScanV==scanNum);
    for i = 1:length(scanIndV)
        strNum = scanIndV(i);
        colorNum = relStrNumV(strNum);
        if isempty(planC{indexS.structures}(strNum).structureColor)
            color = stateS.optS.colorOrder( mod(colorNum-1, size(stateS.optS.colorOrder,1))+1,:);
            planC{indexS.structures}(strNum).structureColor = color;
        end
    end
    % Check for scanType field and populate it with Series description
    if isempty(planC{indexS.scan}(scanNum).scanType) && ...
            isfield(planC{indexS.scan}(scanNum).scanInfo(1),'DICOMHeaders') && ...
            isfield(planC{indexS.scan}(scanNum).scanInfo(1).DICOMHeaders,'SeriesDescription')
        planC{indexS.scan}(scanNum).scanType = planC{indexS.scan}(scanNum).scanInfo(1).DICOMHeaders.SeriesDescription;
    end
    % Save SOPInstanceUID and SOPClassUID within scanInfo
    if ~isfield(planC{indexS.scan}(scanNum).scanInfo(1),'sopInstanceUID') || ...
            isempty(planC{indexS.scan}(scanNum).scanInfo(1).sopInstanceUID) || ...
            isempty(planC{indexS.scan}(scanNum).scanInfo(1).patientID) || ...
            isempty(planC{indexS.scan}(scanNum).scanInfo(1).frameOfReferenceUID)
        if isfield(planC{indexS.scan}(scanNum).scanInfo(1),'DICOMHeaders') ...
                && ~isempty(planC{indexS.scan}(scanNum).scanInfo(1).DICOMHeaders)
            for slcNum = 1:length(planC{indexS.scan}(scanNum).scanInfo)
                planC{indexS.scan}(scanNum).scanInfo(slcNum).sopInstanceUID = ...
                    planC{indexS.scan}(scanNum).scanInfo(slcNum).DICOMHeaders.SOPInstanceUID;
                planC{indexS.scan}(scanNum).scanInfo(slcNum).sopClassUID = ...
                    planC{indexS.scan}(scanNum).scanInfo(slcNum).DICOMHeaders.SOPClassUID;
                planC{indexS.scan}(scanNum).scanInfo(slcNum).seriesInstanceUID = ...
                    planC{indexS.scan}(scanNum).scanInfo(slcNum).DICOMHeaders.SeriesInstanceUID;
                %                 planC{indexS.scan}(scanNum).scanInfo(slcNum).patientBirthDate = ...
                %                     planC{indexS.scan}(scanNum).scanInfo(slcNum).DICOMHeaders.PatientBirthDate;
                if isfield(planC{indexS.scan}(scanNum).scanInfo(slcNum).DICOMHeaders,'FrameofReferenceUID')
                    planC{indexS.scan}(scanNum).scanInfo(slcNum).frameOfReferenceUID = ...
                        planC{indexS.scan}(scanNum).scanInfo(slcNum).DICOMHeaders.FrameofReferenceUID;
                end
                if isfield(planC{indexS.scan}(scanNum).scanInfo(slcNum).DICOMHeaders,'PatientID')
                    planC{indexS.scan}(scanNum).scanInfo(slcNum).patientID = ...
                        planC{indexS.scan}(scanNum).scanInfo(slcNum).DICOMHeaders.PatientID;
                end
            end
        end
    end
    % Save image orientation to scanInfo
    if ~isfield(planC{indexS.scan}(scanNum).scanInfo(1),'imageOrientationPatient') || ...
            isempty(planC{indexS.scan}(scanNum).scanInfo(1).imageOrientationPatient)
        if isfield(planC{indexS.scan}(scanNum).scanInfo(1).DICOMHeaders,'ImageOrientationPatient')
            imgOriV = planC{indexS.scan}(scanNum).scanInfo(1).DICOMHeaders.ImageOrientationPatient;
            [planC{indexS.scan}(scanNum).scanInfo(:).imageOrientationPatient] = deal(imgOriV);
        end
    end
    if ~isfield(planC{indexS.scan}(scanNum).scanInfo(1),'imagePositionPatient') || ...
            isempty(planC{indexS.scan}(scanNum).scanInfo(1).imagePositionPatient)
        if isfield(planC{indexS.scan}(scanNum).scanInfo(1).DICOMHeaders,'ImagePositionPatient')
            for slc = 1:length(planC{indexS.scan}(scanNum).scanInfo)
                planC{indexS.scan}(scanNum).scanInfo(slc).imagePositionPatient = ...
                    planC{indexS.scan}(scanNum).scanInfo(slc).DICOMHeaders.ImagePositionPatient;
            end
        end
    end
end

%Check dose-grid
for doseNum = 1:length(planC{indexS.dose})
    if length(planC{indexS.dose}(doseNum).zValues) > 1
        if planC{indexS.dose}(doseNum).zValues(2) - planC{indexS.dose}(doseNum).zValues(1) < 0
            planC{indexS.dose}(doseNum).zValues = flipud(planC{indexS.dose}(doseNum).zValues);
            %planC{indexS.dose}(doseNum).doseArray = flipdim(planC{indexS.dose}(doseNum).doseArray,3);
            planC{indexS.dose}(doseNum).doseArray = flip(planC{indexS.dose}(doseNum).doseArray,3);
        end
    end
    % Save image orientation and position to dose field
    if ~isfield(planC{indexS.dose}(doseNum),'imageOrientationPatient') || ...
            isempty(planC{indexS.dose}(doseNum).imageOrientationPatient)
        if isfield(planC{indexS.dose}(doseNum).DICOMHeaders,'ImageOrientationPatient')
            imgOriV = planC{indexS.dose}(doseNum).DICOMHeaders.ImageOrientationPatient;
            planC{indexS.dose}(doseNum).imageOrientationPatient = imgOriV;
        end
    end
    if ~isfield(planC{indexS.dose}(doseNum),'imagePositionPatient') || ...
            isempty(planC{indexS.dose}(doseNum).imagePositionPatient)
        if isfield(planC{indexS.dose}(doseNum).DICOMHeaders,'ImagePositionPatient')
            imgPosV = planC{indexS.dose}(doseNum).DICOMHeaders.ImagePositionPatient;
            planC{indexS.dose}(doseNum).imagePositionPatient = imgPosV;
        end
    end
end

%Check whether uniformized data is in cellArray format.
if ~isempty(planC{indexS.structureArray}) && iscell(planC{indexS.structureArray}(1).indicesArray)
    planC = setUniformizedData(planC,planC{indexS.CERROptions});
    indexS = planC{end};
end

if length(planC{indexS.structureArrayMore}) ~= length(planC{indexS.structureArray})
    for saNum = 1:length(planC{indexS.structureArray})
        if saNum == 1
            planC{indexS.structureArrayMore} = struct('indicesArray', {[]},...
                'bitsArray', {[]},...
                'assocScanUID',{planC{indexS.structureArray}(saNum).assocScanUID},...
                'structureSetUID', {planC{indexS.structureArray}(saNum).structureSetUID});
            
        else
            planC{indexS.structureArrayMore}(saNum) = struct('indicesArray', {[]},...
                'bitsArray', {[]},...
                'assocScanUID',{planC{indexS.structureArray}(saNum).assocScanUID},...
                'structureSetUID', {planC{indexS.structureArray}(saNum).structureSetUID});
        end
    end
end

% Get CERR version of last save
if length(planC{indexS.header})>0 &&... 
        isfield(planC{indexS.header},'lastSavedInVer')...
        && ~isempty(planC{indexS.header}.lastSavedInVer)
    CERRImportVersion = planC{indexS.header}.lastSavedInVer;
elseif length(planC{indexS.header})>0 && ...
        isfield(planC{indexS.header},'CERRImportVersion')...
        && ~isempty(planC{indexS.header}.CERRImportVersion)
    CERRImportVersion = planC{indexS.header}.CERRImportVersion;
else
    CERRImportVersion = '0';
end

%Check DSH Points for old CERR versions
if str2num(CERRImportVersion(1)) < 4
    bug_found = 1;
    for structNum = 1:length(planC{indexS.structures})
        if ~isempty(planC{indexS.structures}(structNum).DSHPoints)
            planC = getDSHPoints(planC, stateS.optS, structNum);
        end
    end
end

% Fix RTOG orientation for HFP scans
if str2num(strtok(CERRImportVersion, ',')) < 5.2
    for scanNum = 1:length(planC{indexS.scan})
        if isfield(planC{indexS.scan}(scanNum).scanInfo(1),'DICOMHeaders') ...
                && ~isempty(planC{indexS.scan}(scanNum).scanInfo(1).DICOMHeaders) ...
                && isfield(planC{indexS.scan}(scanNum).scanInfo(1).DICOMHeaders,'PatientPosition')
            %pPos = planC{indexS.scan}(scanNum).scanInfo(1).DICOMHeaders.PatientPosition;
            imgOriV = planC{indexS.scan}(scanNum).scanInfo(1).DICOMHeaders.ImageOrientationPatient;
        else
            %pPos = '';
            imgOriV = [];
        end
        if  ~isempty(imgOriV) && max(abs((imgOriV(:) - [-1 0 0 0 -1 0]'))) < 1e-3 % Position: HFP
            planC = flipAlongX(scanNum, planC);
            bug_found = 1;
        end
    end
end

% Add radiopharma params to scanInfo
for scanNum = 1:length(planC{indexS.scan})
    if isfield(planC{indexS.scan}(scanNum).scanInfo(1),'DICOMHeaders') ...
            && ~isempty(planC{indexS.scan}(scanNum).scanInfo(1).DICOMHeaders) ...
            && any(strcmpi(planC{indexS.scan}(scanNum).scanInfo(1).imageType,{'PT','PET'})) ...
            && isempty(planC{indexS.scan}(scanNum).scanInfo(1).decayCorrection)
        for slcNum = 1:size(planC{indexS.scan}(scanNum).scanArray,3)
            dicomhd = planC{indexS.scan}(scanNum).scanInfo(slcNum).DICOMHeaders;
            ptweight = [];
            if isfield(dicomhd,'PatientWeight')
                ptweight = dicomhd.PatientWeight;
            elseif isfield(dicomhd,'PatientsWeight')
                ptweight = dicomhd.PatientsWeight;
            end
            injectionTime = ...
                dicomhd.RadiopharmaceuticalInformationSequence.Item_1.RadiopharmaceuticalStartTime;
            halfLife = ...
                dicomhd.RadiopharmaceuticalInformationSequence.Item_1.RadionuclideHalfLife;
            injectedDose = ...
                dicomhd.RadiopharmaceuticalInformationSequence.Item_1.RadionuclideTotalDose;
            seriesTime = dicomhd.SeriesTime;
            decayCorrection = dicomhd.DecayCorrection;
            correctedImage = dicomhd.CorrectedImage;    
            imageUnits = dicomhd.Units;
            petActivityConcentrationScaleFactor = [];
            if isfield(dicomhd,'ActivityConcentrationScaleFactor')
                petActivityConcentrationScaleFactor = ...
                    dicomhd.ActivityConcentrationScaleFactor;
            end
            patientSize = [];
            if isfield(dicomhd,'PatientSize')
                patientSize = dicomhd.PatientSize;
            end
            
            planC{indexS.scan}(scanNum).scanInfo(slcNum).patientWeight = ...
                ptweight;
            planC{indexS.scan}(scanNum).scanInfo(slcNum).patientSize = ...
                patientSize;
            planC{indexS.scan}(scanNum).scanInfo(slcNum).petActivityConcentrationScaleFactor = ...
                petActivityConcentrationScaleFactor;
            planC{indexS.scan}(scanNum).scanInfo(slcNum).acquisitionTime = ...
                dicomhd.AcquisitionTime;
            planC{indexS.scan}(scanNum).scanInfo(slcNum).injectionTime = ...
                injectionTime;
            planC{indexS.scan}(scanNum).scanInfo(slcNum).halfLife = ...
                halfLife;
            planC{indexS.scan}(scanNum).scanInfo(slcNum).injectedDose = ...
                injectedDose;
            planC{indexS.scan}(scanNum).scanInfo(slcNum).seriesTime = ...
                seriesTime;
            planC{indexS.scan}(scanNum).scanInfo(slcNum).decayCorrection = ...
                decayCorrection;
            planC{indexS.scan}(scanNum).scanInfo(slcNum).correctedImage = ...
                correctedImage;
            planC{indexS.scan}(scanNum).scanInfo(slcNum).imageUnits = ...
                imageUnits;
            
        end
    end
end

% Check for GSPS and make it empty if no objects are present
if length(planC{indexS.GSPS}) == 1 && isempty(planC{indexS.GSPS}.SOPInstanceUID)
    planC{indexS.GSPS}(1) = [];
end

% Check for IM UIDs
if ~isempty(planC{indexS.IM}) && isfield(planC{indexS.IM}(1),'IMUID') && isempty(planC{indexS.IM}(1).IMUID)
    planC = createIMuids(planC);
end

% Check visible flag for structures. Set it to 1 if it is an empty string
for i = 1:length(planC{indexS.structures})
    if isempty(planC{indexS.structures}(i).visible)
        planC{indexS.structures}(i).visible = 1;
    end
end

% Overwrite the existing CERR file if a bug is found and fixed
if forceSaveFlag == 1 || (~isempty(stateS) && isfield(stateS.optS,'overwrite_CERR_File') && stateS.optS.overwrite_CERR_File == 1 && bug_found)
    try
        if exist('fileName','var')
            % do nothing
        elseif isfield(stateS,'CERRFile')
            fileName = stateS.CERRFile;
        end
        planC = save_planC(planC, stateS.optS, 'passed', fileName);
    catch
        disp('Could not overwrite the exisitng file. Please save manually')
    end
end

