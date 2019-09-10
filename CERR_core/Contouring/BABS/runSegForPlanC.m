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
cerrPath = fullfile(fullClientSessionPath,'ctCERR');
mkdir(cerrPath)
outputCERRPath = fullfile(fullClientSessionPath,'segmentedOrigCERR');
mkdir(outputCERRPath)
segResultCERRRPath = fullfile(fullClientSessionPath,'segResultCERR');
mkdir(segResultCERRRPath)
% create subdir within fullSessionPath for output h5 files
outputH5Path = fullfile(fullClientSessionPath,'outputH5');
mkdir(outputH5Path);
% create subdir within fullSessionPath for input h5 files
inputH5Path = fullfile(fullClientSessionPath,'inputH5');
mkdir(inputH5Path);


% Write planC to CERR .mat file
cerrFileName = fullfile(cerrPath,'cerrFile.mat');
save_planC(planC,[],'passed',cerrFileName);

% algorithm
algorithmC = {};
%algorithm = 'CT_Heart_DeepLab^CT_Atria_DeepLab^CT_Pericardium_DeepLab^CT_HeartStructure_DeepLab^CT_Ventricles_DeepLab';
%algorithm = 'CT_Heart_DeepLab';

[algorithmC{end+1},remStr] = strtok(algorithm,'^');
while ~isempty(remStr)
    [algorithmC{end+1},remStr] = strtok(remStr,'^');
end

if iscell(algorithmC) || ~iscell(algiorithmC) && ~strcmpi(algorithmC,'BABS')
    
    containerPath = varargin{1};
    for k=1:length(algorithmC)
        
        %%% =========== common for client and server
        scan3M = getScanForDeepLearnSeg(cerrPath,algorithmC{k}); % common for client or server
        if isempty(scan3M)
            %no matching struct
            return;
        end
        
        %%% =========== common for client and server
        success = writeH5ForDeepLearnSeg(scan3M,fullClientSessionPath, cerrFileName); % common for client and server
        
        %%% =========== have a flag to tell whether the container runs on the client or a remote server
        success = callDeepLearnSegContainer(algorithmC{k}, containerPath, fullClientSessionPath, sshConfigS); % different workflow for client or session
        
        %%% =========== common for client and server
        success = joinH5CERR(segResultCERRRPath, cerrPath, outputH5Path, algorithmC{k},scan3M);
        
        %success = segmentationWrapper(cerrPath,segResultCERRRPath,fullClientSessionPath,containerPath,algorithm);
        % Read segmentation from segResultCERRRPath to display in viewer
        segFileName = fullfile(segResultCERRRPath,'cerrFile.mat');
        planD = loadPlanC(segFileName);
        indexSD = planD{end};
        scanIndV = 1;
        doseIndV = [];
        numSegStr = length(planD{indexSD.structures});
        numOrigStr = length(planC{indexS.structures});
        structIndV = 1:numSegStr;
        planC = planMerge(planC, planD, scanIndV, doseIndV, structIndV, '');
        numSegStr = numSegStr - numOrigStr;
        for iStr = 1:numSegStr
            planC = copyStrToScan(numOrigStr+iStr,1,planC);
        end
        planC = deleteScan(planC, 2);
        
        save_planC(planC,[],'passed',cerrFileName);
        
        
    end
    
else %'BABS'
    
    babsPath = varargin{1};
    success = babsSegmentation(cerrPath,fullClientSessionPath,babsPath,segResultCERRRPath);
    
    % Read segmentation from segResultCERRRPath to display in viewer
    segFileName = fullfile(segResultCERRRPath,'cerrFile.mat');
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
%exportCERRtoDICOM(cerrPath,segResultCERRRPath,outputCERRPath,outputDicomPath)


% Remove session directory
%rmdir(fullClientSessionPath, 's')

% refresh the viewer
if ~isempty(stateS) && ishandle(stateS.handle.CERRSliceViewer)
    stateS.structsChanged = 1;
    CERRRefresh
end



