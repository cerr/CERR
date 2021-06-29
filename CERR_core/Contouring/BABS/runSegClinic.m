function success =  runSegClinic(inputDicomPath,outputDicomPath,...
    sessionPath,algorithm,savePlanc,varargin)
% function success = runSegClinic(inputDicomPath,outputDicomPath,...
%   sessionPath,algorithm,varargin)
%
% This function serves as a wrapper for different types of segmentations.
%---------------------------------------------------------------------------------------
% INPUT:
% inputDicomPath - path to input DICOM directory which needs to be segmented.
% outputDicomPath - path to write DICOM RTSTRUCT for resulting segmentation.
% sessionPath - path to write temporary segmentation metadata.
% algorithm - string which specifies segmentation algorith
% varargin - additional algorithm-specific inputs
%
% Following directories are created within the session directory:
% --- ctCERR: contains CERR file/s of input DICOM.
% --- segmentedOrigCERR: CERR file with resulting segmentation fused with
% original CERR file.
% --- segResultCERR: CERR file with segmentation. Note that CERR file can
% be cropped based on initial segmentation.
%
% EXAMPLE: to run BABS segmentation
% inputDicomPath = '';
% outputDicomPath = '';
% sessionPath = '';
% algorithm = 'BABS';
% babsPath = '';
% savePlanc = 'Yes'; or 'No'
% success = runSegClinic(inputDicomPath,outputDicomPath,sessionPath,algorithm,babsPath);
%
% ------------------------------------------------------------------------------------
% APA, 12/14/2018
% RKP, 9/11/19 Updates for compatibility with training pipeline
% AI, 2/7/2020 Added separate DICOM export functions for BABS and DL algorithms
% AI, 3/5/2020 Updates to handle multiple algorithms

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

% Import DICOM to CERR
tic
recursiveFlag = true;
importDICOM(inputDicomPath,cerrPath,recursiveFlag);
toc

% Parse algorithm and convert to cell arrray
algorithmC = split(algorithm,'^');

%% Run inference
if ~any(strcmpi(algorithmC,'BABS'))
    
    containerPathStr = varargin{1};
    % Parse container path and convert to cell arrray
    containerPathC = split(containerPathStr,'^');
    numAlgorithms = numel(algorithmC);
    numContainers = numel(containerPathC);
    if numAlgorithms > 1 && numContainers == 1
        containerPathC = repmat(containerPathC,numAlgorithms,1);
    elseif numAlgorithms ~= numContainers
        error('Mismatch between number of algorithms and containers')
    end
    origCerrPath = cerrPath;
    allLabelNamesC = {};
    for k=1:length(algorithmC)
        
        %Read config file
        configFilePath = fullfile(getCERRPath,'ModelImplementationLibrary',...
            'SegmentationModels','ModelConfigurations',...
            [algorithmC{k}, '_config.json']);
        userOptS = readDLConfigFile(configFilePath);
        
        %Delete previous inputs where needed
        modelFmt = userOptS.modelInputFormat;
        modInputPath = fullfile(fullSessionPath,['input',modelFmt]);
        modOutputPath = fullfile(fullSessionPath,['output',modelFmt]);
        if exist(modInputPath, 'dir')
            rmdir(modInputPath, 's')
        end
        if exist(modOutputPath, 'dir')
            rmdir(modOutputPath, 's')
        end
        
        %Copy config file to session dir
        copyfile(configFilePath,fullSessionPath);
        
        % Run segmentation algorithm
        success = segmentationWrapper(cerrPath,...
            fullSessionPath,containerPathC{k},algorithmC{k});
        
        %Get list of label names
        if ischar(userOptS.strNameToLabelMap)
            labelDatS = readDLConfigFile(fullfile(labelPath,...
                userOptS.strNameToLabelMap));
            labelMapS = labelDatS.strNameToLabelMap;
        else
            labelMapS = userOptS.strNameToLabelMap;
        end
        allLabelNamesC = [allLabelNamesC,{labelMapS.structureName}];
    end
    
    % Export segmentations to DICOM RTSTRUCT files
    savePlancFlag = 0;
    if strcmpi(savePlanc,'yes')
        savePlancFlag = 1;
    end
    fprintf('\nExporting to DICOM format...');
    tic
    exportCERRtoDICOM(origCerrPath,allLabelNamesC,outputCERRPath,...
        outputDicomPath,algorithm,savePlancFlag)
    toc
    
else
    
    babsPath = varargin{1};
    success = babsSegmentation(cerrPath,fullSessionPath,babsPath,segResultCERRPath);
    
    % Export the RTSTRUCT file
    savePlancFlag = 0;
    if strcmpi(savePlanc,'yes')
        savePlancFlag = 1;
    end
    exportCERRtoDICOM_forBABS(origCerrPath,segResultCERRPath,outputCERRPath,...
        outputDicomPath,algorithm,savePlancFlag)
    
end

% Remove session directory
rmdir(fullSessionPath, 's')

success = 0;

