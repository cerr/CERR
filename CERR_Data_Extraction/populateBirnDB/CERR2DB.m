function infoS = CERR2DB(dirPath)
%CERR2DB.m
%This function writes CERR plans under dirPath to Database
%
%APA, 02/28/2011

%Store Log
infoS = struct('fullFileName','','allStructureNames','','allDoseNames','','error','');
infoS(1) = [];


%Find all CERR files
fileC = {};
if strcmpi(dirPath,'\') || strcmpi(dirPath,'/')
    filesTmp = getCERRfiles(dirPath(1:end-1));
else
    filesTmp = getCERRfiles(dirPath);
end
fileC = [fileC filesTmp];

%Extablish Database connection
setdbprefs({'NullStringRead';'NullNumberRead';'DataReturnFormat';'errorhandling'},{'';'NaN';'structure';'report'})

%Loop over CERR plans
for iFile=1:length(fileC)
        
    drawnow
    
    fileNum = length(infoS)+1;
    
    try
        planC = loadPlanC(fileC{iFile},tempdir);
        planC = updatePlanFields(planC);
    catch
        disp([fileC{iFile}, ' failed to load'])
        infoS(fileNum).error = 'Failed to Load';
        continue
    end
    
    infoS(fileNum).fullFileName = fileC{iFile};
    
    global planC
    
    indexS = planC{end};
    
    % Quality Assurance
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
    
    stateS.optS = CERROptions;
    
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
    
    indexS = planC{end};
    
    %BIRN Postgressql (Development)
    % conn = database('BCCA_Prostate','cerr','cerr~data','org.postgresql.Driver','jdbc:postgresql://128.9.132.88:5432/');    
    conn = database('BCCA_HeadNeck','cerr','cerr~data','org.postgresql.Driver','jdbc:postgresql://128.9.132.88:5432/');    
    
    for scanNum = 1:length(planC{indexS.scan})
        
        scanUID = planC{indexS.scan}(1).scanUID;
        
        %Find the matching patient in the database
        sqlq_find_patient = ['Select patient_id from scan where scan_uid = ''', scanUID,''''];
        pat_raw = exec(conn, sqlq_find_patient);
        pat = fetch(pat_raw);
        pat = pat.Data;
        if isstruct(pat)
            patient_id = pat.patient_id{1};
            break;
        else
            %New Patient
        end
        
    end
    
    %Insert New patient to database
    if ~isstruct(pat)
        patient_id = char(java.util.UUID.randomUUID);
        study_id = '837ec0db-e4b3-4c61-be80-f6909447f3fa'; % BCCA Prostate
        study_id = '209aa534-4f33-4c8c-8ae3-05d92a29e17e'; % BCCA Head & Neck
        %study_id = '4cd0969a-a64f-46af-905e-d015f2c193bf'; % DUKE Lung        
        insert(conn,'patient',{'patient_id','study_id','first_name','last_name','cerr_file_location'},{patient_id,study_id,'','',fileC{iFile}});
    end
    
    %Write "scan" to database
    write_scan_to_db(conn,patient_id)
    
    %Write "structure" database
    write_structure_to_db(conn,patient_id)
    
    %Write "dose" database
    write_dose_to_db(conn,patient_id)
    
    %Write "DVH" to database
    write_dvh_to_db(conn,patient_id)
    
    %Record log
    infoS(fileNum).allStructureNames = {planC{indexS.structures}.structureName};    
    infoS(fileNum).allDoseNames = {planC{indexS.dose}.fractionGroupID};
    
    close(conn)
    
    clear global planC
    
end


return;

