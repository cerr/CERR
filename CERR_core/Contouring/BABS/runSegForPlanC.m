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


%% Create session directory to write segmentation metadata

global stateS

indexS = planC{end};

% % Use series uid in temporary folder name
% if isfield(stateS,'scanSet') && ~isempty(stateS.scanSet)
%     scanNum = stateS.scanSet;
% else
%     scanNum = 1;
% end
% if isfield(planC{indexS.scan}(scanNum).scanInfo(1),'seriesInstanceUID') && ...
%         ~isempty(planC{indexS.scan}(scanNum).scanInfo(1).seriesInstanceUID)
%     folderNam = planC{indexS.scan}(scanNum).scanInfo(1).seriesInstanceUID;
% else
%     folderNam = dicomuid;
% end
% Create folderName with uid
folderNam = char(javaMethod('createUID','org.dcm4che3.util.UIDUtils'));
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

%% Create sub-directories  
%-For CERR files
mkdir(fullClientSessionPath)
cerrPath = fullfile(fullClientSessionPath,'dataCERR');
mkdir(cerrPath)
outputCERRPath = fullfile(fullClientSessionPath,'segmentedOrigCERR');
mkdir(outputCERRPath)
segResultCERRPath = fullfile(fullClientSessionPath,'segResultCERR');
mkdir(segResultCERRPath)
%-For structname-to-label map
labelPath = fullfile(fullClientSessionPath,'outputLabelMap');
mkdir(labelPath);

testFlag = true;

%% Run segmentation algorithm

% Parse algorithm and convert to cell arrray
confirm_recursive_rmdir(0)
algorithmC = strsplit(algorithm,'^');

if length(algorithmC) > 1 || ...
        (length(algorithmC)==1 && ~strcmpi(algorithmC,'BABS'))
    
    containerPathStr = varargin{1};
    % Parse container path and convert to cell arrray
    containerPathC = strsplit(containerPathStr,'^');
    numAlgorithms = numel(algorithmC);
    numContainers = numel(containerPathC);
    if numAlgorithms > 1 && numContainers == 1
        containerPathC = repmat(containerPathC,numAlgorithms,1);
    elseif numAlgorithms ~= numContainers
        error('Mismatch between number of algorithms and containers')
    end
    
    for k=1:length(algorithmC)
        
        %Get the config file path
        configFilePath = fullfile(getCERRPath,'ModelImplementationLibrary',...
            'SegmentationModels', 'ModelConfigurations',...
            [algorithmC{k}, '_config.json']);
        
        %Read config file
        userOptS = readDLConfigFile(configFilePath);
        
        %Delete previous inputs where needed
        modelFmt = userOptS.modelInputFormat;
        modInputPath = fullfile(fullClientSessionPath,['input',modelFmt]);
        modOutputPath = fullfile(fullClientSessionPath,['output',modelFmt]);
        if exist(modInputPath, 'dir')
            rmdir(modInputPath, 's')            
        end
        mkdir(modInputPath);
        if exist(modOutputPath, 'dir')
            rmdir(modOutputPath, 's')            
        end
        mkdir(modOutputPath);

        
        %Copy config file to session dir
        copyfile(configFilePath,fullClientSessionPath);
        
        if nargin==7 && ~isnan(varargin{2})
            scanNum = varargin{2};
        else
            scanNum = [];
        end
        
        %Pre-process data
        if ishandle(hWait)
            waitbar(0.1,hWait,'Extracting scan and mask');
        end
        [scanC, maskC, scanNumV, userOptS, coordInfoS, planC] = ...
            extractAndPreprocessDataForDL(userOptS,planC,testFlag,scanNum);
        %Note: mask3M is empty for testing
        
        if ishandle(hWait)
            waitbar(0.2,hWait,'Segmenting structures...');
        end
        
        %Export scans to model input format
        scanOptS = userOptS.scan;
        passedScanDim = userOptS.passedScanDim;
        filePrefixForHDF5 = 'cerrFile';
        
        %Loop over scans
        for nScan = 1:length(scanOptS)
            
            %Append identifiers to o/p name
            idS = scanOptS(nScan).identifier;
            idListC = cellfun(@(x)(idS.(x)),fieldnames(idS),'un',0);
            appendStr = strjoin(idListC,'_');
            idOut = [filePrefixForHDF5,'_',appendStr];
            
            %Get o/p dirs and dim
            outDirC = getOutputH5Dir(modInputPath,scanOptS(nScan),'');
            
            %Write to model i/p fmt
            writeDataForDL(scanC{nScan},maskC{nScan},coordInfoS,...
                passedScanDim,modelFmt,outDirC,idOut,testFlag);
            
        end
        
        %Flag indicating if container runs on client or remote server
        if ishandle(hWait)
            wbch = allchild(hWait);
            jp = wbch(1).JavaPeer;
            jp.setIndeterminate(1)
        end
        
        %Call container and execute model
        [success,gitHash] = callDeepLearnSegContainer(algorithmC{k}, ...
            containerPathC{k}, fullClientSessionPath, sshConfigS,...
            userOptS.batchSize); % different workflow for client or session
        
        %%% =========== common for client and server
        roiDescrpt = '';
        if isfield(userOptS,'roiGenerationDescription')
            roiDescrpt = userOptS.roiGenerationDescription;
        end
        roiDescrpt = [roiDescrpt, '  __git_hash:',gitHash];
        userOptS.roiGenerationDescription = roiDescrpt;
        
        %Read mask files
        if ishandle(hWait)
            waitbar(0.9,hWait,'Writing segmentation results to CERR');
        end
        outFmt = userOptS.modelOutputFormat;
        passedScanDim = userOptS.passedScanDim;
        outC = stackDLMaskFiles(fullClientSessionPath,outFmt,passedScanDim);
        
        %Import masks to planC
        identifierS = userOptS.structAssocScan.identifier;
        if ~isempty(fieldnames(userOptS.structAssocScan.identifier))
            origScanNum = getScanNumFromIdentifiers(identifierS,planC);
        else
            origScanNum = 1; %Assoc with first scan by default
        end
        outScanNum = scanNumV(origScanNum);
        userOptS.scan(outScanNum) = userOptS(origScanNum).scan;
        userOptS.scan(outScanNum).origScan = origScanNum;
        planC  = joinH5planC(outScanNum,outC{1},labelPath,userOptS,planC);
        
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

