function planC = importDICOM(source,destn)
% function importDICOM(source,destn)
%
% Function to import DICOM from source and write CERR file to destn.
%
% APA, 8/14/2018

zipFlag = 'No';

%% Import DICOM to CERR
% Read options file
% Possibly pass it as an input to handle different options for different
% types of datasets
pathStr = getCERRPath;
optName = [pathStr,'CERROptions.json'];
optS = opts4Exe(optName);

mergeScansFlag = 'No';
try
    planC = dicomDirToPlanC(source,optS,mergeScansFlag);
catch
    error(['Cannot convert ',source, ' to planC'])
end

% build the filename for storing planC
if source(end) == filesep
    [~,folderNam] = fileparts(source(1:end-1));
else
    [~,folderNam] = fileparts(source);
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
        outFileName = [outFileName,'_duplicate_',num2str(rand(1))];
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


