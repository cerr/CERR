function [planC,origScanNumV,allLabelNamesC,dcmExportOptS] = ...
    runAIforPlanC(planC,clientSessionPath,algorithm,cmdFlag,...
    newSessionFlag,sshConfigFile,hWait,varargin)
%function [planC,origScanNumV,allLabelNamesC,dcmExportOptS] = ...
% runAIForPlanC(planC,clientSessionPath,algorithm,cmdFlag,...
% newSessionFlag,sshConfigFile,hWait,varargin)
% This function serves as a wrapper for different types of AI models.
%--------------------------------------------------------------------------
% INPUTS:
% planC             : planC 
% clientSessionPath : path to write temporary segmentation metadata.
% algorithm         : string which specifies segmentation algorithm
% cmdFlag           : "condaEnv" or "singContainer"
% newSessionFlag    : Set to false to use existing session dir
%                     (default:true).
% --Optional inputs---
% varargin{1}: Path to singularity container OR conda env
% varargin{2}: Scan no. (replaces scan identifier)
% varargin{3}: Flag to skip export of structure masks (Default:true (off))
%--------------------------------------------------------------------------
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
% cmdFlag = 'condaEnv';
% condaEnvList = '/path/to/conda_archive';
% newSessionFlag = true;
% planC = runAIforPlanC(planC,sessionPath,algorithm,cmdFlag,...
%    newSessionFlag,[],[],condaEnvList);
%--------------------------------------------------------------------------
% APA, 06/10/2019
% RKP, 09/18/19 Updates for compatibility with training pipeline

%% Create session directory to write segmentation metadata

global stateS

%% Create session dir
if newSessionFlag
    init_ML_DICOM
    folderNam = char(javaMethod('createUID','org.dcm4che3.util.UIDUtils'));
    dateTimeV = clock;
    randNum = 1000.*rand;
    sessionDir = ['session',folderNam,num2str(dateTimeV(4)), num2str(dateTimeV(5)),...
        num2str(dateTimeV(6)), num2str(randNum)];

    fullClientSessionPath = fullfile(clientSessionPath,sessionDir);

    %Create sub-directories
    %-For CERR files
    mkdir(fullClientSessionPath)
    cerrPath = fullfile(fullClientSessionPath,'dataCERR');
    mkdir(cerrPath)
    outputCERRPath = fullfile(fullClientSessionPath,'outputOrigCERR');
    mkdir(outputCERRPath)
    AIresultCERRPath = fullfile(fullClientSessionPath,'AIResultCERR');
    mkdir(AIresultCERRPath)
    %-For structname-to-label map
    AIoutputPath = fullfile(fullClientSessionPath,'AIoutput');
    mkdir(AIoutputPath);
else
    fullClientSessionPath = clientSessionPath;
    cerrPath = fullfile(fullClientSessionPath,'dataCERR');
    AIresultCERRPath = fullfile(fullClientSessionPath,'AIResultCERR');
    AIoutputPath = fullfile(fullClientSessionPath,'AIoutput');
end
sshConfigS = [];
if ~isempty(sshConfigFile)
    sshConfigS = jsondecode(fileread(sshConfigFile));
    fullServerSessionPath = fullfile(clientSessionPath,sessionDir);
    sshConfigS.fullServerSessionPath = fullServerSessionPath;
end

if nargin>9
    skipMaskExport = varargin{3};
else
    skipMaskExport = true;
end

% Set flag for recursive directory removal in GNU Octave
if isempty(getMLVersion)
    confirm_recursive_rmdir(0)
end

%Parse algorithm and convert to cell array
algorithmC = strsplit(algorithm,'^');

if length(algorithmC) > 1 || ...
        (length(algorithmC)==1 && ~strcmpi(algorithmC,'BABS'))
    containerPathC = varargin{1};
    % Parse container path and convert to cell arrray
    if ~iscell(containerPathC)
        containerPathC = strsplit(containerPathC,'^');
    end
    numAlgorithms = numel(algorithmC);
    numContainers = numel(containerPathC);
    if numAlgorithms > 1 && numContainers == 1
        containerPathC = repmat(containerPathC,numAlgorithms,1);
    elseif numAlgorithms ~= numContainers
        error('Mismatch between number of algorithms and containers')
    end

    %% Run AI model
    % Loop over algorithms
    allLabelNamesC = {};
    createSessionFlag = false;
    for k=1:length(algorithmC)

        if nargin>=9 && ~isnan(varargin{2})
            scanNum = varargin{2};
        else
            scanNum = [];
        end

        %Pre-process data for segmentation
        [activate_cmd,run_cmd,userOptS,~,scanNumV,planC] = ...
            prepDataForAImodel(planC, fullClientSessionPath ,algorithmC(k), ...
            cmdFlag,createSessionFlag,containerPathC{k},{},skipMaskExport,...
            scanNum);

        %Flag indicating if container runs on client or remote server
        if ishandle(hWait)
            wbch = allchild(hWait);
            jp = wbch(1).JavaPeer;
            jp.setIndeterminate(1)
        end

        %Call container and execute model
        tic
        roiDescrpt = '';
        if strcmpi(cmdFlag,'singcontainer') && exist('sshConfigS','var')...
                && isempty(sshConfigS)
            callDeepLearnSegContainer(algorithmC{k}, ...
                containerPathC{k}, fullClientSessionPath, sshConfigS,...
                userOptS.batchSize); % different workflow for client or session
            gitHash = 'unavailable';
            [~,hashChk] = system(['singularity apps ' containerPathC{k},...
                ' | grep get_hash'],'-echo');
            if ~isempty(hashChk)
                [~,gitHash] = system(['singularity run --app get_hash ',...
                    containerPathC{k}],'-echo');
            end
            roiDescrpt = [roiDescrpt, '  __git_hash:',gitHash];
            userOptS.output.labelMap.roiGenerationDescription = roiDescrpt;
        else
            cmd = [activate_cmd,' && ',run_cmd];
            disp(cmd)
            status = system(cmd);
            if ~isfield(userOptS.output.labelMap,'roiGenerationDescription')
                userOptS.output.labelMap.roiGenerationDescription = roiDescrpt;
            end
            gitHash = 'unavailable';

        end
        toc

        %Process model outputs
        [planC,origScanNumV,labelNamesC,dcmExportOptS] = ...
            processAndImportAIOutput(planC,userOptS,scanNumV,...
            algorithmC(k),gitHash,fullClientSessionPath,cmdFlag,hWait);
        allLabelNamesC = [allLabelNamesC,labelNamesC];

    end

    if ishandle(hWait)
        close(hWait);
    end

else %'BABS'
    
    babsPath = varargin{1};
    success = babsSegmentation(cerrPath,fullClientSessionPath,babsPath,...
              AIresultCERRPath);
    
    % Read segmentation from segResultCERRRPath to display in viewer
    segFileName = fullfile(AIresultCERRPath,'cerrFile.mat');
    indexS = planC{end};
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

% Remove session directory
if newSessionFlag
    rmdir(fullClientSessionPath, 's')
end

% refresh the viewer
if ~isempty(stateS) && (isfield(stateS,'handle') && ishandle(stateS.handle.CERRSliceViewer))
    stateS.structsChanged = 1;
    CERRRefresh
end

