function planC = planMerge(planC, planD, scanIndV, doseIndV, structIndV, mergefileName)
%"planMerge"
%   Merge part or all of planD into planC.  If no other parameters
%   beyond the two plans are provided, all doses, scans, structures, and
%   uniformized data from planD are added to planC.
%
%    If it exists, the scan numbers in scanIndV from planD are merged
%   into planC.  If scanIndV = [], no scans are merged.  If scanIndV =
%   'all' all scans are merged.
%
%   If it exists, the dose numbers in doseIndV from planD are merged
%   into planC.  If doseIndV = [], no doses are merged.  If doseIndV =
%   'all' all doses are merged.
%
%   If it exists, the dose numbers in doseIndV from planD are merged
%   into planC.  If doseIndV = [], no doses are merged.  If doseIndV =
%   'all' all doses are merged.
%
%   Merged structures require that the scan and uniformized data they were
%   associated with be merged along with them.  This is done automatically
%   for any selected structs.
%
%JRA 3/2/05
%
%Usage:
%MERGE ALL
%   planC = planMerge(planC, planD);
%
%MERGE ALL scans, NO doses, ALL structs
%   planC = planMerge(planC, planD, 'all', [], 'all');
%
%MERGE ALL scans, doses 1 and 2.
%   planC = planMerge(planC, planD, 'all', [1 2], []);
%
%
% copyright (c) 2001-2006, Washington University in St. Louis.
% Permission is granted to use or modify only for non-commercial,
% non-treatment-decision applications, and further only if this header is
% not removed from any file. No warranty is expressed or implied for any
% use whatever: use at your own risk.  Users can request use of CERR for
% institutional review board-approved protocols.  Commercial users can
% request a license.  Contact Joe Deasy for more information
% (radonc.wustl.edu@jdeasy, reversed).

global stateS
% indexSD = planD{end};

planD = updatePlanFields(planD);

% Quality assure
if exist('mergefileName','var')
    planD = quality_assure_planC(mergefileName, planD);
end

indexSD = planD{end};

doses   = planD{indexSD.dose};
scans   = planD{indexSD.scan};
structs = planD{indexSD.structures};
IM      = planD{indexSD.IM};
gsps    = planD{indexSD.GSPS};

%Handle case of 'all' or unpassed indVs.
if (exist('scanIndV') & strcmpi(scanIndV, 'all')) | ~exist('scanIndV')
    scanIndV = 1:length(scans);
end
if (exist('doseIndV') & strcmpi(doseIndV, 'all')) | ~exist('doseIndV')
    doseIndV = 1:length(doses);
end
if (exist('structIndV') & strcmpi(structIndV, 'all')) | ~exist('structIndV')
    structIndV = 1:length(structs);
end

if isempty(scanIndV) & isempty(doseIndV) & isempty(structIndV)
    CERRStatusString('Exiting Plan Merge GUI....')
    return;
end

%Check that passed indices are within range of the plan.
if ~all(ismember(scanIndV, 1:length(scans)))
    error('Invalid scan index passed to planMerge. Scan does not exist.');
end
if ~all(ismember(doseIndV, 1:length(doses)))
    error('Invalid dose index passed to planMerge. Dose does not exist.');
end
if ~all(ismember(structIndV, 1:length(structs)))
    error('Invalid structure index passed to planMerge. Structure does not exist.');
end


indexSC     = planC{end};
nDose       = length(planC{indexSC.dose});
nScans      = length(planC{indexSC.scan});
nStructs    = length(planC{indexSC.structures});
nIM         = length(planC{indexSC.IM});
nGSPS       = length(planC{indexSC.GSPS});

% Record existing and added UIDs
existingScanUIDc      = {planC{indexSC.scan}.scanUID};
existingDoseUIDc      = {planC{indexSC.dose}.doseUID};
existingStructureUIDc = {planC{indexSC.structures}.strUID};
addedScanUIDc         = {planD{indexSD.scan}.scanUID};
addedDoseUIDc         = {planD{indexSD.dose}.doseUID};
addedStructureUIDc    = {planD{indexSD.structures}.strUID};

% Find scans, doses, structs that already exist
scansWithSameUID   = find(ismember(addedScanUIDc,existingScanUIDc));
dosesWithSameUID   = find(ismember(addedDoseUIDc,existingDoseUIDc));
structsWithSameUID = find(ismember(addedStructureUIDc,existingStructureUIDc));

if any(scansWithSameUID) && ~isempty(scanIndV)
    oldScanUIc = {scans.scanUID};
    for scanNum = 1:length(planD{indexSD.scan})
        scans(scanNum).scanUID = createUID('scan');
    end
    newScanUIc = {scans.scanUID};
    scansWithSameUID = 0;
    
    % Change the associated scanUID fields for dose and structures
    for iDose = 1:length(doses)
        indMatch = find(strcmp(doses(iDose).assocScanUID,oldScanUIc));
        if ~isempty(indMatch)
            doses(iDose).assocScanUID = newScanUIc{indMatch};
        end
    end
    for iStr = 1:length(structs)
        indMatch = find(strcmp(structs(iStr).assocScanUID,oldScanUIc));
        if ~isempty(indMatch)
            structs(iStr).assocScanUID = newScanUIc{indMatch};
        end
    end  
    for iStr = 1:length(planD{indexSD.structureArray})
        indMatch = find(strcmp(planD{indexSD.structureArray}(iStr).assocScanUID,oldScanUIc));
        planD{indexSD.structureArray}(iStr).assocScanUID = newScanUIc{indMatch};
        planD{indexSD.structureArrayMore}(iStr).assocScanUID = newScanUIc{indMatch};
    end
end

newScanNum  = nScans + 1;

if ~isempty(structs)
    [structs.associatedScan] = deal(newScanNum);
end

%Get associated scans requested structs.
[assocScansV, relStructNum]       = getStructureAssociatedScan(structIndV, planD);

%Check color assignment for displaying structures
if ~isfield(stateS,'optS')
    stateS.optS = opts4Exe([getCERRPath,'CERROptions.json']);
end
for scanNum = 1:length(planD{indexSD.scan})
    scanStrIndV = find(assocScansV==scanNum);
    for i = 1:length(scanStrIndV)
        strNum = scanStrIndV(i);
        colorNum = relStructNum(strNum);
        if isempty(structs(relStructNum(strNum)).structureColor)
            color = stateS.optS.colorOrder( mod(colorNum-1, size(stateS.optS.colorOrder,1))+1,:);
            structs(relStructNum(strNum)).structureColor = color;
        end
    end
end

% %Check for mesh representation and load meshes into memory
% currDir = cd;
% meshDir = fileparts(which('libMeshContour.dll'));
% cd(meshDir)
% for strNum = 1:length(structs)
%     if isfield(structs(strNum),'meshRep') && ~isempty(structs(strNum).meshRep) && structs(strNum).meshRep
%         try
%             calllib('libMeshContour','loadSurface',structs(strNum).strUID,structs(strNum).meshS)
%         catch
%             structs(strNum).meshRep    = 0;
%             structs(strNum).meshS      = [];
%         end
%     end
% end
% cd(currDir)

%Check dose-grid
for doseNum = 1:length(doses)
    if doses(doseNum).zValues(2) - doses(doseNum).zValues(1) < 0
        doses(doseNum).zValues = flipud(doses(doseNum).zValues);
        doses(doseNum).doseArray = flipdim(doses(doseNum).doseArray,3);
    end
    %Check y grid
    if doses(doseNum).verticalGridInterval > 0
        doses(doseNum).coord2OFFirstPoint = doses(doseNum).coord2OFFirstPoint + abs(doses(doseNum).verticalGridInterval) * doses(doseNum).sizeOfDimension2;
        doses(doseNum).verticalGridInterval = -doses(doseNum).verticalGridInterval;
        doses.doseArray = flipdim(doses(doseNum).doseArray,1);
    end    
end

%Check DSH Points for old CERR versions
if ~isfield(planD{indexSD.header},'CERRImportVersion') || (isfield(planD{indexSD.header},'CERRImportVersion') && isempty(planD{indexSD.header}.CERRImportVersion))
    CERRImportVersion = '0';
else
    CERRImportVersion = planD{indexSD.header}.CERRImportVersion;
end

if str2num(CERRImportVersion(1)) < 4
    for structNum = 1:length(planD{indexSD.structures})
        if ~isempty(planD{indexSD.structures}(structNum).DSHPoints)
            planD = getDSHPoints(planD, stateS.optS, structNum);
        end
    end
end

%Check whether uniformized data is in cellArray format.
if ~isempty(planD{indexSD.structureArray}) && iscell(planD{indexSD.structureArray}(1).indicesArray)
    planD = setUniformizedData(planD,planD{indexSD.CERROptions});
    indexSD = planD{end};
end

if length(planD{indexSD.structureArrayMore}) ~= length(planD{indexSD.structureArray})
    for saNum = 1:length(planD{indexSD.structureArray})
        if saNum == 1
            planD{indexSD.structureArrayMore} = struct('indicesArray', {[]},...
                'bitsArray', {[]},...
                'assocScanUID',planD{indexSD.structureArray}(saNum).assocScanUID,...
                'structureSetUID', planD{indexSD.structureArray}(saNum).structureSetUID);

        else
            planD{indexSD.structureArrayMore}(saNum) = struct('indicesArray', {[]},...
                'bitsArray', {[]},...
                'assocScanUID',{planD{indexSD.structureArray}(saNum).assocScanUID},...
                'structureSetUID', {planD{indexSD.structureArray}(saNum).structureSetUID});
        end
    end
end

uniData = planD{indexSD.structureArray};
uniDataMore = planD{indexSD.structureArrayMore};

%If structures are being imported and there is no scan, create a dummy
%scan to associate the structures with.
if isempty(scans) && ~isempty(structIndV)
    planD = createDummyScan(planD);
    planD = setUniformizedData(planD);
    uniData = planD{indexSD.structureArray};
    uniDataMore = planD{indexSD.structureArrayMore};
    scans = planD{indexSD.scan};
end

%Display warning for non-square voxels
nonSquareVoxelWarn(planD)

% %correct IM Structure names to include prefix '2 - ' etc.
% for i = 1:length(IM)
%     if isfield(IM(i).IMDosimetry,'goals')
%         for iG = 1:length(IM(i).IMDosimetry.goals)
%             IM(i).IMDosimetry.goals(iG).structName = [num2str(nScans+1) ' - ' IM(i).IMDosimetry.goals(iG).structName];
%         end
%     end
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% DK added to change the Associated scan if no scan is selected.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Just to customize input
if isempty(scanIndV) && nScans == 1
    whichScan = 1;
    whichScanUID = planC{indexSC.scan}(whichScan).scanUID;
else
    ansBtnDS = '';
    if isempty(scanIndV) && ~isempty(doseIndV) && ~isempty(structIndV)
        
        ansBtnDS = questdlg('Do you want to Change scan association for Dose and Structures','Scan Association','Yes','No','Yes');
        
    elseif isempty(scanIndV) && isempty(doseIndV) && ~isempty(structIndV)
        
        ansBtnDS = questdlg('Do you want to Change scan association for Structures','Scan Association','Yes','No','Yes');
    end
    
    % If answer is Yes
    if strcmp(ansBtnDS,'Yes')
        if nScans == 1
            whichScan = 1;
        else
            prompt={['Enter one of the Scan Number b/w ' num2str(1 : nScans) ' to associate this data with']};
            def={'1'};
            dlgTitle = 'Pick Associated Scan Number';
            lineNo=1;
            whichScan = inputdlg(prompt,dlgTitle,lineNo,def);
            whichScan = str2num(whichScan{:});
        end
        whichScanUID = planC{indexSC.scan}(whichScan).scanUID;
    else
        whichScan = [];
        whichScanUID = [];
        %Must include associated scans of any structures being merged.
        scanIndV = sort(union(scanIndV, assocScansV));
    end
end

scanIndV   = setdiff(scanIndV,scansWithSameUID);
doseIndV   = setdiff(doseIndV,dosesWithSameUID);
structIndV = setdiff(structIndV,structsWithSameUID);

%Remove structures from planD's uniformized data if they aren't being imported.
toDelete = setdiff(1:length(structs), [structIndV]);
if ~isempty(uniData) && ~isempty(toDelete)
    planD    = delUniformStr(toDelete, planD);
    uniData = planD{indexSD.structureArray};
    uniDataMore = planD{indexSD.structureArrayMore};    
end

%Filter the actual structArray by structs to include.
structs = structs(structIndV);
oldStructAssocScanUidC = {structs.assocScanUID};

%Add structs to planC, modifying name and associatd scan.
for i=1:length(structs)
    if isempty(whichScan)
        oldAssocScan                = assocScansV(i);
        newAssocScan                = nScans + find(scanIndV == oldAssocScan);
    else
        newAssocScan                = whichScan;
        structs(i).assocScanUID     = whichScanUID;
    end
    % structs(i).structureName    = [num2str(newAssocScan) ' - ' structs(i).structureName];
    structs(i).associatedScan   = newAssocScan;
    planC{indexSC.structures}    = dissimilarInsert(planC{indexSC.structures}, structs(i), nStructs+i);
end

%Filter by scans to include
scans = scans(scanIndV);

% reuniformize scan if new structures are added.
matchingScanUIDs = ismember(oldStructAssocScanUidC,{planC{indexSC.scan}.scanUID, scans.scanUID});
if ~all(matchingScanUIDs)   
    structuresToUniformize = nStructs + find(~matchingScanUIDs);
    for iUniformize = 1:length(structuresToUniformize)
        planC = updateStructureMatrices(planC, structuresToUniformize(iUniformize));
    end
end

%Add scans to planC, along with structure array data if the original scan
%number was in assocScansV.  IE, if any merged structures require the structure
%array data it is included now, at the same time as it's scan.

for i = 1:length(planC{indexSC.scan})
    if ~isfield(planC{indexSC.scan}(i),'transM')
        planC{indexSC.scan}(i).transM = eye(4);
    end
end

for i=1:length(scans)
    planC{indexSC.scan} = dissimilarInsert(planC{indexSC.scan}, scans(i), nScans+i);
    if ismember(scanIndV(i), assocScansV) && length(uniData) >= i
        planC{indexSC.structureArray} = dissimilarInsert(planC{indexSC.structureArray}, uniData(i), nScans+i);
        planC{indexSC.structureArrayMore} = dissimilarInsert(planC{indexSC.structureArrayMore}, uniDataMore(i), nScans+i);
    end
end

%Filter by doses to include.
doses = doses(doseIndV);

for i=1:length(doses)
    if ~isempty(whichScan)
        doses(i).assocScanUID = whichScanUID;
        doses(i).associatedScan = whichScan;
    end
    planC{indexSC.dose} = dissimilarInsert(planC{indexSC.dose}, doses(i), nDose+i);
end

%Merge all IM's until filter is implemented
for i=1:length(IM)
    planC{indexSC.IM} = dissimilarInsert(planC{indexSC.IM}, IM(i), nIM+i);
end


%Merge all GSPS objects
for i=1:length(gsps)
    planC{indexSC.GSPS} = dissimilarInsert(planC{indexSC.GSPS}, gsps(i), nGSPS+i);
end

%Uniformize the plan if necessary.
if isempty(whichScan)
    for i=1:length(planC{indexSC.scan})
        if ~isUniformized(i, planC)
            planC = setUniformizedData(planC);
            break;
        end
    end
else
    planC = setUniformizedData(planC);
end

% Save scan statistics for fast image rendering
if exist('stateS','var') && isfield(stateS,'handle')

    for scanNum = 1:length(scans)
        %scanUID = ['c',repSpaceHyp(scans(scanNum).scanUID(max(1,end-61):end))];
        %stateS.scanStats.minScanVal.(scanUID) = single(min(scans(scanNum).scanArray(:)));
        %stateS.scanStats.maxScanVal.(scanUID) = single(max(scans(scanNum).scanArray(:)));
        % Set Window and Width from DICOM header, if available
        CTLevel = '';
        CTWidth = '';
        if isfield(scans(scanNum).scanInfo(1),'DICOMHeaders') && ...
                isfield(scans(scanNum).scanInfo(1).DICOMHeaders,'WindowCenter')...
                && isfield(scans(scanNum).scanInfo(1).DICOMHeaders,'WindowWidth')
            CTLevel = scans(scanNum).scanInfo(1).DICOMHeaders.WindowCenter(end);
            CTWidth = scans(scanNum).scanInfo(1).DICOMHeaders.WindowWidth(end);
        end
        if ~isnumeric(CTLevel) || ~isnumeric(CTWidth)
            CTLevel = str2double(get(stateS.handle.CTLevel,'String'));
            CTWidth = str2double(get(stateS.handle.CTWidth,'String'));
        end
        scanUID = ['c',repSpaceHyp(scans(scanNum).scanUID(max(1,end-61):end))];
        stateS.scanStats.CTLevel.(scanUID) = CTLevel;
        stateS.scanStats.CTWidth.(scanUID) = CTWidth;
        stateS.scanStats.windowPresets.(scanUID) = 1;
        % Set colormap
        stateS.scanStats.Colormap.(scanUID) = 'gray256';
    end
end
