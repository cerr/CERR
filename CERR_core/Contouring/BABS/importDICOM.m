function planC = importDICOM(source,destn,recursiveFlag)
% function importDICOM(source,destn)
%
% Function to import DICOM from source and write CERR file to destn.
%
% APA, 8/14/2018

if ~exist('recursiveFlag','var')
    recursiveFlag = false;
end

zipFlag = 'No';

% % Define file and directory filter patterns
% fileFilterC = {'scout','corTmp','sag','report','_nac','mip',...
%     'coronal','sagittal','screen_save'};
% dirFilterC = {'ot'};

% Get all directories and files
tic, 
[filesInCurDir,dirsInCurDir] = rdir(source); 
toc

% Convert to lower case
dirsToImportC = {dirsInCurDir.fullpath};
if isempty(dirsToImportC)
    dirsToImportC = {source};
end

% filter directories containing no files
indV1 = false(1,length(dirsToImportC));
tic,
for dirNum = 1:length(dirsToImportC) 
    dirS = dir(dirsToImportC{dirNum}); 
    if ~all([dirS.isdir])
        indV1(dirNum) = 1;
    end
end
toc
dirsToImportC = dirsToImportC(indV1);


%% Import DICOM to CERR
% Read options file
pathStr = getCERRPath;
optName = [pathStr,'CERROptions.json'];
optS = opts4Exe(optName);

% Import all the dirs
for dirNum = 1:length(dirsToImportC)
    try
        init_ML_DICOM
        %hWaitbar = waitbar(0,'Scanning Directory Please wait...');
        sourceDir = dirsToImportC{dirNum};
        %patient = scandir_mldcm_babs(sourceDir, hWaitbar, 1);
        excludePixelDataFlag = true;
        patient = scandir_mldcm(sourceDir, excludePixelDataFlag, recursiveFlag);
        %close(hWaitbar);
        dcmdirS = struct(['patient_' num2str(1)],patient.PATIENT(1));
        for j = 2:length(patient.PATIENT)
            dcmdirS.(['patient_' num2str(j)]) = patient.PATIENT(j);
        end
        patNameC = fieldnames(dcmdirS);
        mergeScansFlag = 'No';
        combinedDcmdirS = struct('STUDY',dcmdirS.(patNameC{1}).STUDY);
        combinedDcmdirS = struct('STUDY',dcmdirS.(patNameC{1}).STUDY,'info',dcmdirS.(patNameC{1}).info);
        for i = 2:length(patNameC)
            for j = 1:length(dcmdirS.(patNameC{i}).STUDY.SERIES)
                combinedDcmdirS.STUDY.SERIES(end+1) = ...
                    dcmdirS.(patNameC{i}).STUDY.SERIES(j);
            end
        end
        % Pass the java dicom structures to function to create CERR plan
        try
            planC = dcmdir2planC(combinedDcmdirS,mergeScansFlag,optS);
        end

        indexS = planC{end};
        
        % build the filename for storing planC
        if sourceDir(end) == filesep
            [~,folderNam] = fileparts(sourceDir(1:end-1));
        else
            [~,folderNam] = fileparts(sourceDir);
        end
        
        %mrn = planC{indexS.scan}(1).scanInfo(1).DICOMHeaders.PatientID;
        %studyDscr = planC{indexS.scan}(1).scanInfo(1).DICOMHeaders.StudyDescription;
        %seriesDscr = planC{indexS.scan}(1).scanInfo(1).DICOMHeaders.SeriesDescription;
        %modality = planC{indexS.scan}(1).scanInfo(1).DICOMHeaders.Modality;        
        % outFileName = [mrn,'~',studyDscr,'~',seriesDscr,'~',modality];
        
        outFileName = folderNam;
        
        %outFileName = mrn;   % store file names as MRNs
        
        %[~,outFileName] = fileparts(sourceDir);  % store file names as DICOM directory names
        %fullOutFileName = fullfile(destn,fileName);
        
        %Check for duplicate name of fullOutFileName
        if exist('destn','var') && ~isempty(destn)
            dirOut = dir(destn);
            allOutNames = {dirOut.name};
            if any(strcmpi([outFileName,'.mat'],allOutNames))
                fullOutFileName = [outFileName,'_duplicate_',num2str(rand(1))];
            end
            if strcmpi(zipFlag,'Yes')
                saved_fullFileName = fullfile(destn,[outFileName,'.mat.bz2']);
            else
                saved_fullFileName = fullfile(destn,[outFileName,'.mat']);
            end
            
            
            if ~exist(fileparts(saved_fullFileName),'dir')
                mkdir(fileparts(saved_fullFileName))
            end
            save_planC(planC,[], 'passed', saved_fullFileName);
        end
        
    catch
        
        disp(['Cannot convert ',source])
        
    end
end

