function success = runSegClinic(inputDicomPath,outputDicomPath,...
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

% Create session directory to write segmentation metadata

if inputDicomPath(end) == filesep
    [~,folderNam] = fileparts(inputDicomPath(1:end-1));
else
    [~,folderNam] = fileparts(inputDicomPath);
end

dateTimeV = clock;
randNum = 1000.*rand;
sessionDir = ['session',folderNam,num2str(dateTimeV(4)), num2str(dateTimeV(5)),...
    num2str(dateTimeV(6)), num2str(randNum)];

fullSessionPath = fullfile(sessionPath,sessionDir);

% Create directories to write CERR files
mkdir(fullSessionPath)
cerrPath = fullfile(fullSessionPath,'dataCERR');
mkdir(cerrPath)
outputCERRPath = fullfile(fullSessionPath,'segmentedOrigCERR');
mkdir(outputCERRPath)
segResultCERRPath = fullfile(fullSessionPath,'segResultCERR');
mkdir(segResultCERRPath)

% Import DICOM to CERR
importDICOM(inputDicomPath,cerrPath);

% Get algorithm
if ~iscell(algorithm)
    algorithm = {algorithm};
end

[algorithmC,remStr] = strtok(algorithm,'^');
if iscell(remStr)
    isEmptyC = cellfun(@isempty,remStr,'Un',0);
    isEmpty = any([isEmptyC{:}]);
    isEqualC = cellfun(@(x)isequal(x,""),remStr,'Un',0);
    isEqual = any([isEqualC{:}]);
    while ~isEmpty && ~isEqual
        [algorithmC,remStr] = strtok(remStr,'^');
        isEmptyC = cellfun(@isempty,remStr,'Un',0);
        isEmpty = any([isEmptyC{:}]);
        isEqualC = cellfun(@(x)isequal(x,""),remStr,'Un',0);
        isEqual = any([isEqualC{:}]);
    end
else
    while ~isempty(remStr) && ~isequal(remStr,"")
        [algorithmC,remStr] = strtok(remStr,'^');
        remStr = char(remStr);
    end
end

%Run inference
if iscell(algorithmC) || ~iscell(algorithmC) && ~strcmpi(algorithmC,'BABS')
    
    containerPath = varargin{1};
    origCerrPath = cerrPath;
    allLabelNamesC = {};
    for k=1:length(algorithmC)
        
        %Delete previous inputs where needed
        inputH5Path = fullfile(fullSessionPath,'inputH5');
        outputH5Path = fullfile(fullSessionPath,'outputH5');
        if exist(inputH5Path, 'dir')
            rmdir(inputH5Path, 's')
        end
        if exist(outputH5Path, 'dir')
            rmdir(outputH5Path, 's')
        end
        
        % Run segmentation algorithm
        success = segmentationWrapper(cerrPath,segResultCERRPath,fullSessionPath,containerPath,algorithmC{k});
        
        %Get list of label names
        configFilePath = fullfile(getCERRPath,'ModelImplementationLibrary','SegmentationModels',...
            'ModelConfigurations', [algorithmC{k}, '_config.json']);
        userOptS = readDLConfigFile(configFilePath);
        allLabelNamesC = [allLabelNamesC,{userOptS.strNameToLabelMap.structureName}];
        
    end
    
    % Export segmentations to DICOM RTSTRUCT files
    savePlancFlag = 0;
    if strcmpi(savePlanc,'yes')
        savePlancFlag = 1;
    end
    exportCERRtoDICOM(origCerrPath,allLabelNamesC,outputCERRPath,...
        outputDicomPath,algorithm,savePlancFlag)
    
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

success = 1;
