function planC = runSegForPlanCInCondaEnv(planC,sessionPath,algorithm,functionName,hWait,varargin)
% function planC = runSegForPlanCInCondaEnv(planC,sessionPath,algorithm,functionName,hWait,varargin)
%
% This function serves as a wrapper for auto-segmentation algorithms.
% -------------------------------------------------------------------------------
% INPUTS:
% planC
% sessionPath  -  Directory for writitng temporary segmentation metadata.
% algorithm    -  Algorthim name. For full list, see:
%                   https://github.com/cerr/CERR/wiki/Auto-Segmentation-models.
%                 Pass caret-delimited list to chain multilple algorithms, e.g:
%                   algorithm = ['CT_ChewingStructures_DeepLabV3^',...
%                   'CT_Larynx_DeepLabV3^CT_PharyngealConstrictor_DeepLabV3'];
% functionName -  Path to python wrapper function.
%                 Pass caret-delimited list to chain multilple wrappers.
% varargin     -  Additional algorithm-specific inputs
%                 varargin{1} : conda env name.
%--------------------------------------------------------------------------------
% EXAMPLE:
% Specify conda path in CERRoptions.JSON, e.g.:
%    "condaPath" : "C:/Miniconda3/"
%    It is assumed that subdirectory 'condabin' exists and contains activate script
%    and subdirectory 'envs' exists and contains environment 'condaEnvName'.
% To run segmentation, open a CERR-format file using the GUI, followed by:
%   global planC
%   sessionPath = '/path/to/session/dir';
%   algorithm = 'CT_Heart_DeepLab';
%   functionName = '/path/to/python_wrapper.py';
%   condaEnvName = 'testEnv';
%   planC = runSegForPlanCInCondaEnv(planC,sessionPath,algorithm,functionName,[],condaEnvName);
%--------------------------------------------------------------------------------
% AI, 08/25/2020

global stateS

%% Create session directory to write segmentation metadata
indexS = planC{end};
% Create temp. dir labelled by series UID, local time and date
if isfield(planC{indexS.scan}.scanInfo(1),'seriesInstanceUID') && ...
        ~isempty(planC{indexS.scan}.scanInfo(1).seriesInstanceUID)
    folderNam = planC{indexS.scan}.scanInfo(1).seriesInstanceUID;
else
    folderNam = dicomuid;
end
dateTimeV = clock;
randNum = 1000.*rand;
sessionDir = ['session',folderNam,num2str(dateTimeV(4)), num2str(dateTimeV(5)),...
    num2str(dateTimeV(6)), num2str(randNum)];
fullSessionPath = fullfile(sessionPath,sessionDir);


%% Create directories to write CERR files
mkdir(fullSessionPath)
cerrPath = fullfile(fullSessionPath,'dataCERR');
mkdir(cerrPath)
outputCERRPath = fullfile(fullSessionPath,'segmentedOrigCERR');
mkdir(outputCERRPath)
segResultCERRPath = fullfile(fullSessionPath,'segResultCERR');
mkdir(segResultCERRPath)
% Create sub-directories for input & output h5 files
outputH5Path = fullfile(fullSessionPath,'outputH5');
mkdir(outputH5Path);
inputH5Path = fullfile(fullSessionPath,'inputH5');
mkdir(inputH5Path);
testFlag = true;
confirm_recursive_rmdir(0)

%% Get conda installation path
optS = opts4Exe([getCERRPath,'CERROptions.json']);
condaPath = fullfile(optS.condaPath,'bin');
condaEnvName = varargin{1};

%% Parse algorithm & functionName and convert to cell arrray
algorithmC = strsplit(algorithm,'^');
functionNameC = strsplit(functionName,'^');
numAlgorithms = numel(algorithmC);
numWrapperFunctions = numel(functionNameC);
if numAlgorithms ~= numWrapperFunctions
    error('Mismatch between no. specified algorithms and wrapper functions')
end

condaEnvList = varargin{1};
condaEnvListC = strsplit(condaEnvList,'^');
numContainers = numel(condaEnvListC);
if numAlgorithms > 1 && numContainers == 1
    condaEnvListC = repmat(condaEnvListC,numAlgorithms,1);
elseif numAlgorithms ~= numContainers
    error('Mismatch between no. specified algorithms and conda envs.')
end

% Loop over algorithms
for k=1:length(algorithmC)
    
    %Clear previous contents of session dir
    inputH5Path = fullfile(fullSessionPath,'inputH5');
    outputH5Path = fullfile(fullSessionPath,'outputH5');
    if exist(inputH5Path, 'dir')
        rmdir(inputH5Path, 's')
        mkdir(inputH5Path);
    end
    if exist(outputH5Path, 'dir')
        rmdir(outputH5Path, 's')
        mkdir(outputH5Path);
    end
    
    % Get config file path
    configFilePath = fullfile(getCERRPath,'ModelImplementationLibrary',...
        'SegmentationModels', 'ModelConfigurations',...
        [algorithmC{k}, '_config.json']);
    
    % Pre-process and export data to HDF5 format
    if ishandle(hWait)
        waitbar(0.1,hWait,'Extracting scan and mask');
    end
    userOptS = readDLConfigFile(configFilePath);
    if nargin==7 && ~isnan(varargin{2})
        batchSize = varargin{2};
    else
        batchSize = userOptS.batchSize;
    end
    [scanC, mask3M, planC] = extractAndPreprocessDataForDL(userOptS,planC,...
                              testFlag);
    %Note: mask3M is empty for testing
    if ishandle(hWait)
        waitbar(0.2,hWait,'Segmenting structures...');
    end
    outDirC = getOutputH5Dir(inputH5Path,userOptS,'');
    disp(outDirC{1})
    filePrefixForHDF5 = 'cerrFile';
    writeHDF5ForDL(scanC,mask3M,userOptS.passedScanDim,outDirC,...
                   filePrefixForHDF5,testFlag);
    
    % Call python wrapper and execute model
    pth = getenv('PATH');
    condaBinPath = fullfile(optS.condaPath,'condabin');
    condaEnvPath = fullfile(optS.condaPath,'envs',condaEnvListC{k});
    newPth = [condaBinPath,pth];
    setenv('PATH',newPth)
    wrapperFunc = functionNameC{k};    
    command = sprintf('. /usr/local/etc/profile.d/conda.sh && conda activate %s && python %s %s %s %s',...
        condaEnvPath, wrapperFunc, inputH5Path, outputH5Path,...
        num2str(userOptS.batchSize));
    disp(command)    
    tic
    status = system(command);
    toc
    
    % Read structure masks
    if ishandle(hWait)
        waitbar(0.9,hWait,'Writing segmentation results to CERR');
    end
    outC = stackHDF5Files(fullSessionPath,userOptS.passedScanDim); %Updated
    
    % Import to planC
    planC  = joinH5planC(outC{1},userOptS,planC); % only 1 file
    
    % Post-process segmentation
    planC = postProcStruct(planC,userOptS);
    
end

if ishandle(hWait)
    close(hWait);
end


% Remove session directory
rmdir(fullSessionPath, 's')

% Refresh Viewer
if ~isempty(stateS) && (isfield(stateS,'handle') && ishandle(stateS.handle.CERRSliceViewer))
    stateS.structsChanged = 1;
    CERRRefresh
end

end