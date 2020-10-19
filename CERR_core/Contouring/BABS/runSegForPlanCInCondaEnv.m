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
% AI, 09/21/2020

global stateS

%% Create session directory to write segmentation metadata
indexS = planC{end};
% Create temp. dir labelled by series UID, local time and date
if isfield(planC{indexS.scan}(1).scanInfo(1),'seriesInstanceUID') && ...
        ~isempty(planC{indexS.scan}(1).scanInfo(1).seriesInstanceUID)
    folderNam = planC{indexS.scan}(1).scanInfo(1).seriesInstanceUID;
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

%% Get conda installation path
optS = opts4Exe([getCERRPath,'CERROptions.json']);
condaPath = optS.condaPath;

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
    [scanC, maskC, scanNumV, userOptS, planC] = ...
        extractAndPreprocessDataForDL(userOptS,planC,testFlag);
    %Note: mask3M is empty for testing
    if ishandle(hWait)
        waitbar(0.2,hWait,'Segmenting structures...');
    end
    
    %Export to H5 format
    tic
    fprintf('\nWriting to H5 format...\n');
    filePrefixForHDF5 = 'cerrFile';
    passedScanDim = userOptS.passedScanDim;
    scanOptS = userOptS.scan;
    %Loop over scan types
    for n = 1:size(scanC,1)
        %Append identifiers to o/p name
        if length(scanOptS)>1
            idS = scanOptS(n).identifier;
            idListC = cellfun(@(x)(idS.(x)),fieldnames(idS),'un',0);
            appendStr = strjoin(idListC,'_');
            idOut = [filePrefixForHDF5,'_',appendStr];
        else
            idOut = filePrefixForHDF5;
        end
        %Get o/p dirs & dim
        outDirC = getOutputH5Dir(inputH5Path,scanOptS(n),'');
        %Write to HDF5
        writeHDF5ForDL(scanC{n},maskC{n},passedScanDim,outDirC,idOut,testFlag);
    end
    
    % Call python wrapper and execute model
    pth = getenv('PATH');
    condaBinPath = fullfile(condaPath,'condabin;');
    condaEnvPath = fullfile(condaPath,'envs',condaEnvListC{k});
    newPth = [condaBinPath,pth];
    setenv('PATH',newPth)
    wrapperFunc = functionNameC{k};
    if ispc
        command = sprintf('call activate %s && python %s %s %s %s',...
            condaEnvPath, wrapperFunc, inputH5Path, outputH5Path,...
            num2str(batchSize));
    else
        condaSrc = fullfile(optS.condaPath,'etc/profile.d/conda.sh');
        command = sprintf('. %s && conda activate %s && python %s %s %s %s',...
            condaSrc, condaEnvPath, wrapperFunc, inputH5Path, outputH5Path,...
            num2str(batchSize));
    end
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
    tic
    identifierS = userOptS.structAssocScan.identifier;
    if ~isempty(fieldnames(userOptS.structAssocScan.identifier))
        origScanNum = getScanNumFromIdentifiers(identifierS,planC);
    else
        origScanNum = 1; %Assoc with first scan by default
    end
    outScanNum = scanNumV(origScanNum);
    userOptS(outScanNum).scan = userOptS(origScanNum).scan;
    userOptS(outScanNum).scan.origScan = origScanNum;
    planC  = joinH5planC(outScanNum,outC{1},userOptS,planC); % only 1 file
    toc
    
    % Post-process segmentation
    planC = postProcStruct(planC,userOptS);
    
    %Delete intermediate (resampled) scans if any
    scanListC = arrayfun(@(x)x.scanType, planC{indexS.scan},'un',0);
    resampScanName = ['Resamp_scan',num2str(origScanNum)];
    matchIdxV = ismember(scanListC,resampScanName);
    if any(matchIdxV)
        deleteScanNum = find(matchIdxV);
        planC = deleteScan(planC,deleteScanNum);
    end
    
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