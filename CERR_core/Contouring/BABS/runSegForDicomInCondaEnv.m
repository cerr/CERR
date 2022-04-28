function success =  runSegForDicomInCondaEnv(inputDicomPath,outputDicomPath,...
    sessionPath,algorithm,condaEnvList,wrapperFunctionList,skipMaskExport)
% function success =  runSegForDicomInCondaEnv(inputDicomPath,outputDicomPath,...
%     sessionPath,algorithm,condaEnvList,wrapperFunctionList,skipMaskExport)
%
% This function serves as a wrapper for different types of segmentations.
%---------------------------------------------------------------------------------------
% INPUT:
% inputDicomPath - path to input DICOM directory which needs to be segmented.
% outputDicomPath - path to write DICOM RTSTRUCT for resulting segmentation.
% sessionPath - path to write temporary segmentation metadata.
% algorithm - string which specifies segmentation algorithm
% --- Optional---
% skipMaskExport - flag to skip export of prior mask
%%---------------------------------------------------------------------------------------
% Following directories are created within the session directory:
% --- ctCERR: contains CERR file/s of input DICOM.
% --- segmentedOrigCERR: CERR file with resulting segmentation fused with
% original CERR file.
% --- segResultCERR: CERR file with segmentation. Note that CERR file can
% be cropped based on initial segmentation.
%
% EXAMPLE:
% inputDicomPath = /path/to/input/dicom/folder;
% outputDicomPath = /path/to/output/dicom/folder;
% sessionPath = '/path/to/directory/for/temp/session';
% algorithm = 'CT_name_of_model';
% condaEnvList = '/location/of/conda/env';
% wrapperFunctionList = '/location/of/inference/wrapper/function'
% success =  runSegForDicomInCondaEnv(inputDicomPath,outputDicomPath,...
%     sessionPath,algorithm,condaEnvList,wrapperFunctionList)
%
% ------------------------------------------------------------------------------------
% APA, AI 04/28/2022

if ~exist('skipMaskExport','var') || ...
        (exist('skipMaskExport','var') && isempty(skipMaskExport))
    skipMaskExport = true;
end

%% Create session directory to write segmentation metadata
if inputDicomPath(end) == filesep
    [~,folderNam] = fileparts(inputDicomPath(1:end-1));
else
    [~,folderNam] = fileparts(inputDicomPath);
end
dateTimeV = clock;
randStr = sprintf('%6.3f',rand*1000);
sessionDir = ['session',folderNam,num2str(dateTimeV(4)), num2str(dateTimeV(5)),...
    num2str(dateTimeV(6)), randStr];
fullSessionPath = fullfile(sessionPath,sessionDir);
while exist(fullSessionPath,'dir')
    randStr = sprintf('%6.3f',rand*1000);
    sessionDir = [sessionDir, randStr];
    fullSessionPath = fullfile(sessionPath,sessionDir);
end

%% Create sub-directories 
%-For  CERR files
mkdir(fullSessionPath)
cerrPath = fullfile(fullSessionPath,'dataCERR');
mkdir(cerrPath)
outputCERRPath = fullfile(fullSessionPath,'segmentedOrigCERR');
mkdir(outputCERRPath)
segResultCERRPath = fullfile(fullSessionPath,'segResultCERR');
mkdir(segResultCERRPath)
%-For structname-to-label map
labelPath = fullfile(fullSessionPath,'outputLabelMap');
mkdir(labelPath);

%% Import DICOM to CERR
tic
recursiveFlag = true;
importDICOM(inputDicomPath,cerrPath,recursiveFlag);
toc

%% Build DICOM export options

% Parse algorithm and convert to cell arrray
algorithmC = split(algorithm,'^');

dcmExportOptS = struct();
dcmExportOptS(1) = [];


configFilePath = fullfile(getCERRPath,'ModelImplementationLibrary',...
    'SegmentationModels','ModelConfigurations',...
    [algorithmC{k}, '_config.json']);
userOptS = readDLConfigFile(configFilePath);

%Get list of label names
if ischar(userOptS.strNameToLabelMap)
    labelDatS = readDLConfigFile(fullfile(labelPath,...
        userOptS.strNameToLabelMap));
    labelMapS = labelDatS.strNameToLabelMap;
else
    labelMapS = userOptS.strNameToLabelMap;
end
allLabelNamesC = [allLabelNamesC,{labelMapS.structureName}];

% Get DICOM export settings
if isfield(userOptS, 'dicomExportOptS')
    if isempty(dcmExportOptS)
        dcmExportOptS = userOptS.dicomExportOptS;
    else
        dcmExportOptS = dissimilarInsert(dcmExportOptS,userOptS.dicomExportOptS);
    end
end


%% Load planC
planCfiles = dir(fullfile(cerrPath,'*.mat'));
for p=1:length(planCfiles)
    
    % Load planC
    planCfiles(p).name
    fileNam = fullfile(planCfiles(p).folder,planCfiles(p).name);
    planC = loadPlanC(fileNam, tempdir);
    planC = quality_assure_planC(fileNam,planC);
    
    % Run Segmentation   
    batchSize = [];
    planC = runSegForPlanCInCondaEnv(planC,sessionPath,algorithm,...
    condaEnvList,wrapperFunctionList,batchSize,skipMaskExport);

    % Save planC to cerrPath
    planC = save_planC(planC,[],'passed',fileNam);
    
    % Write RTSTRUCT to DICOM
    
    % Get scan index to associate final segmentation
    identifierS = userOptS.structAssocScan.identifier;
    if ~isempty(fieldnames(userOptS.structAssocScan.identifier))
        origScanNum = getScanNumFromIdentifiers(identifierS,planC);
    else
        origScanNum = 1; %Assoc with first scan by default
    end    
    exportAISegToDICOM(planC,origScanNum,outputDicomPath,dcmExportOptS,allLabelNamesC)
    
end

success = 0;
