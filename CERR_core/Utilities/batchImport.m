% open a pool of parallel processors
%pool = parpool(4);

% folder to import
%source = 'path/to/source';
%destn = 'path/to/destn'; 
zipFlag = 'No';

% Define file and directory filter patterns
fileFilterC = {'dose','scout','cor','sag','report','_nac','mip',...
    'coronal','sagittal','screen_save'};
dirFilterC = {'ot'};

% Get all directories and files
tic, 
[filesInCurDir,dirsInCurDir] = rdir(source); 
toc

% Convert to lower case
dirNameC = lower({dirsInCurDir.name});
dirFullPathC = lower({dirsInCurDir.fullpath});

% determine back or forward slash
if ispc
    slashType = '\';
else
    slashType = '/';
end

% Filter out files
indV = zeros(1,length(dirNameC));
for i = 1:length(fileFilterC)    
    indC = strfind(dirNameC,fileFilterC{i});
    indV1 = ~cellfun(@isempty, indC);
    indV = indV | indV1;
    sum(indV)
end

% Filter out directories
for i = 1:length(dirFilterC)
    indC = strfind(dirFullPathC,[slashType,dirFilterC{i},slashType]);
    indV1 = ~cellfun(@isempty, indC);
    indV = indV | indV1;
end

% list of directories after filtering NAC's, etc.
dirsToImportC = dirFullPathC(~indV);

% filter directories containing no files
indV1 = false(length(dirsToImportC),1);
tic,
for dirNum = 1:length(dirsToImportC), 
    dirS = dir(dirFullPathC{dirNum}); 
    if ~all([dirS.isdir])
        indV1(dirNum) = 1;
    end
end
toc
dirsToImportC = dirsToImportC(indV1);

%% Import DICOM to CERR
tic
hWaitbar = NaN;
% Import all the dirs
parfor dirNum = 1:length(dirsToImportC)
    try
        init_ML_DICOM
        %hWaitbar = waitbar(0,'Scanning Directory Please wait...');
        sourceDir = dirsToImportC{dirNum};
        patient = scandir_mldcm(sourceDir, hWaitbar, 1);
        %close(hWaitbar);
        dcmdirS = struct(['patient_' num2str(1)],patient.PATIENT(1));
        for j = 2:length(patient.PATIENT)
            dcmdirS.(['patient_' num2str(j)]) = patient.PATIENT(j);
        end
        patNameC = fieldnames(dcmdirS);
        selected = 'all';
        mergeScansFlag = 'No';
        combinedDcmdirS = struct('STUDY',dcmdirS.(patNameC{1}).STUDY,'info',dcmdirS.(patNameC{1}).info);
        if strcmpi(selected,'all')
            combinedDcmdirS = struct('STUDY',dcmdirS.(patNameC{1}).STUDY,'info',dcmdirS.(patNameC{1}).info);
            for i = 2:length(patNameC)
                for j = 1:length(dcmdirS.(patNameC{i}).STUDY.SERIES)
                    combinedDcmdirS.STUDY.SERIES(end+1) = dcmdirS.(patNameC{i}).STUDY.SERIES(j);
                end
            end
            % Pass the java dicom structures to function to create CERR plan
            try
                planC = dcmdir2planC(combinedDcmdirS,mergeScansFlag);
            end
        else
            planC = dcmdir2planC(patient.PATIENT,mergeScansFlag);
        end
        
        indexS = planC{end};
        
        % build the filename for storing planC
        mrn = planC{indexS.scan}(1).scanInfo(1).DICOMHeaders.PatientID;
        %studyDscr = planC{indexS.scan}(1).scanInfo(1).DICOMHeaders.StudyDescription;
        %seriesDscr = planC{indexS.scan}(1).scanInfo(1).DICOMHeaders.SeriesDescription;
        %modality = planC{indexS.scan}(1).scanInfo(1).DICOMHeaders.Modality;
        
        %outFileName = [mrn,'~',studyDscr,'~',seriesDscr,'~',modality];
        %outFileName = mrn;   % store file names as MRNs
        [~,outFileName] = fileparts(sourceDir);  % store file names as DICOM directory names
        %fullOutFileName = fullfile(destn,fileName);
        
        %Check for duplicate name of fullOutFileName
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
        
    catch
        
        disp(['Cannot convert ',sourceDir])
        
    end
end

toc


