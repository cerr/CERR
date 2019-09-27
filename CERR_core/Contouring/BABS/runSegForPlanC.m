function planC = runSegForPlanC(planC,clientSessionPath,algorithm,sshConfigFile,varargin)
% function planC = runSegForPlanC(planC,clientSessionPath,algorithm,SSHkeyPath,serverSessionPath,varargin)
%
% This function serves as a wrapper for different types of segmentations.
%
% INPUT:
% planC - CERR's planC object.
% sessionPath - path to write temporary segmentation metadata.
% algorithm - string which specifies segmentation algorith
% varargin - additional algorithm-specific inputs
%
% Following directories are created within the session directory:
% --- ctCERR: contains CERR file from planC.
% --- segmentedOrigCERR: CERR file with resulting segmentation fused with
% original CERR file.
% --- segResultCERR: CERR file with segmentation. Note that CERR file can
% be cropped based on initial segmentation.
%
% EXAMPLE: to run segmentation, load a plan in CERR followed by:
% global planC
% sessionPath = '/path/to/session/dir';
% algorithm = 'CT_Heart_DeepLab';
% success = runSegClinic(inputDicomPath,outputDicomPath,sessionPath,algorithm);
%
% APA, 06/10/2019
% RKP, 09/18/19 Updates for compatibility with training pipeline


% Create session directory to write segmentation metadata

global stateS

indexS = planC{end};

% Use series uid in temporary folder name
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

fullClientSessionPath = fullfile(clientSessionPath,sessionDir);
sshConfigS = [];
if ~isempty(sshConfigFile)
    sshConfigS = jsondecode(fileread(sshConfigFile));
    fullServerSessionPath = fullfile(clientSessionPath,sessionDir);
    sshConfigS.fullServerSessionPath = fullServerSessionPath;
end

% Create directories to write CERR files
mkdir(fullClientSessionPath)
cerrPath = fullfile(fullClientSessionPath,'dataCERR');
mkdir(cerrPath)
outputCERRPath = fullfile(fullClientSessionPath,'segmentedOrigCERR');
mkdir(outputCERRPath)
segResultCERRPath = fullfile(fullClientSessionPath,'segResultCERR');
mkdir(segResultCERRPath)
% create subdir within fullSessionPath for output h5 files
outputH5Path = fullfile(fullClientSessionPath,'outputH5');
mkdir(outputH5Path);
% create subdir within fullSessionPath for input h5 files
inputH5Path = fullfile(fullClientSessionPath,'inputH5');
mkdir(inputH5Path);

testFlag = true;

% Write planC to CERR .mat file
%cerrFileName = fullfile(cerrPath,'cerrFile.mat');
%save_planC(planC,[],'passed',cerrFileName);

% algorithm
algorithmC = {};

[algorithmC{end+1},remStr] = strtok(algorithm,'^');
while ~isempty(remStr)
    [algorithmC{end+1},remStr] = strtok(remStr,'^');
end

if iscell(algorithmC) || ~iscell(algiorithmC) && ~strcmpi(algorithmC,'BABS')
    
    containerPath = varargin{1};
    
    for k=1:length(algorithmC)
        
        % Get the config file path
        configFilePath = fullfile(getCERRPath,'ModelImplementationLibrary','SegmentationModels', 'ModelConfigurations', [algorithmC{k}, '_config.json']);
        
        userOptS = readDLConfigFile(configFilePath);
        if nargin==6 && ~isnan(varargin{2})
            batchSize = varargin{2};
        else
            batchSize = userOptS.batchSize;
        end
        
        
        [scanC, mask3M] = extractAndPreprocessDataForDL(userOptS,planC,testFlag);
        %Note: mask3M is empty for testing
        filePrefixForHDF5 = 'cerrFile';
        writeHDF5ForDL(scanC,mask3M,userOptS.passedScanDim,inputH5Path,filePrefixForHDF5,testFlag);
        
        
        %%% =========== have a flag to tell whether the container runs on the client or a remote server
        % Call the container and execute model     
        success = callDeepLearnSegContainer(algorithmC{k}, containerPath, fullClientSessionPath, sshConfigS, userOptS.batchSize); % different workflow for client or session
        
        %%% =========== common for client and server
        outC = stackHDF5Files(fullClientSessionPath,userOptS.passedScanDim); %Updated
        
        % Join results back to planC
        planC  = joinH5planC(outC{1},userOptS,planC); % only 1 file 
            
    end
    
else %'BABS'
    
    babsPath = varargin{1};
    success = babsSegmentation(cerrPath,fullClientSessionPath,babsPath,segResultCERRPath);
    
    % Read segmentation from segResultCERRRPath to display in viewer
    segFileName = fullfile(segResultCERRPath,'cerrFile.mat');
    planD = loadPlanC(segFileName);
    indexSD = planD{end};
    scanIndV = 1;
    doseIndV = [];
    numSegStr = length(planD{indexSD.structures});
    numOrigStr = length(planC{indexS.structures});
    structIndV = 1:numSegStr;
    planC = planMerge(planC, planD, scanIndV, doseIndV, structIndV, '');
    for iStr = 1:numSegStr
        planC = copyStrToScan(numOrigStr+iStr,1,planC);
    end
    planC = deleteScan(planC, 2);
    % for structNum = numOrigStr:-1:1
    %     planC = deleteStructure(planC, structNum);
    % end
    
    
end

% Export the RTSTRUCT file
%exportCERRtoDICOM(cerrPath,segResultCERRPath,outputCERRPath,outputDicomPath)


% Remove session directory
rmdir(fullClientSessionPath, 's')

% refresh the viewer
if ~isempty(stateS) && ishandle(stateS.handle.CERRSliceViewer)
    stateS.structsChanged = 1;
    CERRRefresh
end


