function planC = runSegForPlanC(planC,clientSessionPath,algorithm,sshConfigFile,hWait,varargin)
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
scanNum = stateS.scanSet;
if isfield(planC{indexS.scan}(scanNum).scanInfo(1),'seriesInstanceUID') && ...
        ~isempty(planC{indexS.scan}(scanNum).scanInfo(1).seriesInstanceUID)
    folderNam = planC{indexS.scan}(scanNum).scanInfo(1).seriesInstanceUID;
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

% Parse algorithm and convert to cell arrray
algorithmC = split(algorithm,'^');

if length(algorithmC)==1 && ~strcmpi(algorithmC,'BABS')
    
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
    
    for k=1:length(algorithmC)
        
        %Delete previous inputs where needed
        inputH5Path = fullfile(fullClientSessionPath,'inputH5');
        outputH5Path = fullfile(fullClientSessionPath,'outputH5');
        if exist(inputH5Path, 'dir')
            rmdir(inputH5Path, 's')
            mkdir(inputH5Path);
        end
        if exist(outputH5Path, 'dir')
            rmdir(outputH5Path, 's')
            mkdir(outputH5Path);
        end
        
        % Get the config file path
        configFilePath = fullfile(getCERRPath,'ModelImplementationLibrary',...
            'SegmentationModels', 'ModelConfigurations',...
            [algorithmC{k}, '_config.json']);
        
        %Copy config file to session dir
        copyfile(configFilePath,fullClientSessionPath);
        
        % Read config file
        userOptS = readDLConfigFile(configFilePath);
        if nargin==7 && ~isnan(varargin{2})
            batchSize = varargin{2};
        else
            batchSize = userOptS.batchSize;
        end
        
        %Pre-process data
        if ishandle(hWait)
            waitbar(0.1,hWait,'Extracting scan and mask');
        end
        [scanC, maskC, scanNumV, userOptS planC] = ...
            extractAndPreprocessDataForDL(userOptS,planC,testFlag);
        %Note: mask3M is empty for testing
        
        if ishandle(hWait)
            waitbar(0.2,hWait,'Segmenting structures...');
        end
        
        %Export scans to H5
        scanOptS = userOptS.scan;
        passedScanDim = userOptS.passedScanDim;
        filePrefixForHDF5 = 'cerrFile';
        for nScan = 1:length(scanOptS)
            %Append identifiers to o/p name
            if length(scanOptS)>1
                idS = scanOptS(nScan).identifier;
                idListC = cellfun(@(x)(idS.(x)),fieldnames(idS),'un',0);
                appendStr = strjoin(idListC,'_');
                idOut = [filePrefixForHDF5,'_',appendStr];
            else
                idOut = filePrefixForHDF5;
            end
            outDirC = getOutputH5Dir(inputH5Path,scanOptS(nScan),'');
            writeHDF5ForDL(scanC{nScan},maskC{nScan},passedScanDim,outDirC,...
                idOut,testFlag);
        end
        
        %%% =========== have a flag to tell whether the container runs on the client or a remote server
        if ishandle(hWait)
            wbch = allchild(hWait);
            jp = wbch(1).JavaPeer;
            jp.setIndeterminate(1)
        end
        % Call the container and execute model
        success = callDeepLearnSegContainer(algorithmC{k}, ...
            containerPathC{k}, fullClientSessionPath, sshConfigS,...
            userOptS.batchSize); % different workflow for client or session
        
        %%% =========== common for client and server
        if ishandle(hWait)
            waitbar(0.9,hWait,'Writing segmentation results to CERR');
        end
        outC = stackHDF5Files(fullClientSessionPath,userOptS.passedScanDim); %Updated
        
        % Join results back to planC
        identifierS = userOptS.structAssocScan.identifier;
        if ~isempty(fieldnames(userOptS.structAssocScan.identifier))
            origScanNum = getScanNumFromIdentifiers(identifierS,planC);
        else
            origScanNum = 1; %Assoc with first scan by default
        end
        outScanNum = scanNumV(origScanNum);
        userOptS(outScanNum).scan = userOptS(origScanNum).scan;
        userOptS(outScanNum).scan.origScan = origScanNum;
        planC  = joinH5planC(outScanNum,outC{1},userOptS,planC);
        
        % Post-process segmentation
        planC = postProcStruct(planC,userOptS);
        
        
        % Delete intermediate (resampled) scans if any
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
if ~isempty(stateS) && (isfield(stateS,'handle') && ishandle(stateS.handle.CERRSliceViewer))
    stateS.structsChanged = 1;
    CERRRefresh
end

