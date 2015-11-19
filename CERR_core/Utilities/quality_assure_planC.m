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
if isfield(planC{indexS.header}(1), 'lastSavedInVer')
    lastSavedInVer = planC{indexS.header}(1).lastSavedInVer;
else
    lastSavedInVer = '';
end

if ~isempty(str2double(lastSavedInVer)) && (isempty(lastSavedInVer) || str2double(lastSavedInVer) < 4.1) && ~isempty(planC{indexS.structures})
    planC = reRasterAndUniformize(planC);
    bug_found = 1;
end


%Check for mesh representation and load meshes into memory
currDir = cd;
meshDir = fileparts(which('libMeshContour.dll'));
cd(meshDir)
for strNum = 1:length(planC{indexS.structures})
    if isfield(planC{indexS.structures}(strNum),'meshRep') && ~isempty(planC{indexS.structures}(strNum).meshRep) && planC{indexS.structures}(strNum).meshRep
        try
            calllib('libMeshContour','loadSurface',planC{indexS.structures}(strNum).strUID,planC{indexS.structures}(strNum).meshS)
        catch
            planC{indexS.structures}(strNum).meshRep    = 0;
            planC{indexS.structures}(strNum).meshS      = [];
        end
    end
end
cd(currDir)

if ~isfield(stateS,'optS')
    stateS.optS = CERROptions;
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
    if isempty(planC{indexS.scan}(scanNum).scanType) && isfield(planC{indexS.scan}(scanNum).scanInfo(1).DICOMHeaders,'SeriesDescription')
        planC{indexS.scan}(scanNum).scanType = planC{indexS.scan}(scanNum).scanInfo(1).DICOMHeaders.SeriesDescription;
    end
end

%Check dose-grid
for doseNum = 1:length(planC{indexS.dose})
    if planC{indexS.dose}(doseNum).zValues(2) - planC{indexS.dose}(doseNum).zValues(1) < 0
        planC{indexS.dose}(doseNum).zValues = flipud(planC{indexS.dose}(doseNum).zValues);
        planC{indexS.dose}(doseNum).doseArray = flipdim(planC{indexS.dose}(doseNum).doseArray,3);
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

%Check DSH Points for old CERR versions
if ~isfield(planC{indexS.header},'CERRImportVersion') || (isfield(planC{indexS.header},'CERRImportVersion') && isempty(planC{indexS.header}.CERRImportVersion))
    CERRImportVersion = '0';
else
    CERRImportVersion = planC{indexS.header}.CERRImportVersion;
end

if str2num(CERRImportVersion(1)) < 4
    for structNum = 1:length(planC{indexS.structures})
        if ~isempty(planC{indexS.structures}(structNum).DSHPoints)
            planC = getDSHPoints(planC, stateS.optS, structNum);
        end
    end
end

% Check for GSPS and make it empty if no objects are present
if length(planC{indexS.GSPS}) == 1 && isempty(planC{indexS.GSPS}.SOPInstanceUID)
    planC{indexS.GSPS}(1) = [];
end

% Check for IM UIDs
if length(planC{indexS.IM})>0 && isfield(planC{indexS.IM}(1),'IMUID') && isempty(planC{indexS.IM}(1).IMUID)
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

