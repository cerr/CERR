function success = segmentationWrapper(cerrPath,fullSessionPath, containerPath, algorithm)
% function success =heart(cerrPath,segResultCERRPath,fullSessionPath,deepLabContainerPath)
%
% This function serves as a wrapper for the all segmentation models
%
% INPUT: 
% cerrPath - path to the original CERR file to be segmented
% fullSessionPath - path to write temporary segmentation metadata.
% deepLabContainerPath - path to the MR Prostate DeepLab V3+ container on the
% algorithm - name of the algorithm to run
% 
% 
%
%
% RKP, 5/21/2019
% RKP, 9/11/19 Updates for compatibility with training pipeline

%% Get config file path from algorithm name
configFilePath = fullfile(getCERRPath,'ModelImplementationLibrary',...
    'SegmentationModels', 'ModelConfigurations', [algorithm, '_config.json']);
testFlag = true;

% Read config file
userOptS = readDLConfigFile(configFilePath);

%% Create directories to write input, output h5 files
inFmt = userOptS.modelInputFormat;
outFmt = userOptS.modelInputFormat;
modelOutputPath = fullfile(fullSessionPath,['output',outFmt]);
mkdir(modelOutputPath);
modelInputPath = fullfile(fullSessionPath,['input',inFmt]);
mkdir(modelInputPath);


%% Export data to fmt reqd by model 
planCfiles = dir(fullfile(cerrPath,'*.mat'));
for p=1:length(planCfiles)
    
    % Load plan
    planCfiles(p).name
    fileNam = fullfile(planCfiles(p).folder,planCfiles(p).name);
    planC = loadPlanC(fileNam, tempdir);
    planC = quality_assure_planC(fileNam,planC);
    
    %Pre-process scan & mask
    fprintf('\nPre-processing data...\n');
    tic
    [scanC, maskC, scanNumV, userOptS, coordInfoS, planC] = ...
        extractAndPreprocessDataForDL(userOptS,planC,testFlag);
    %Note: mask3M is empty in inference mode
    toc
    
    %% Export to model input format
    tic
    inFmt = userOptS.modelInputFormat;
    fprintf('\nWriting to %s format...\n',inFmt);
    filePrefixForHDF5 = 'cerrFile';
    passedScanDim = userOptS.passedScanDim;
    scanOptS = userOptS.scan;
   
    %Loop over scan types
    for n = 1:size(scanC,1)
        
        %Append identifiers to o/p name
        idS = scanOptS(n).identifier;
        idListC = cellfun(@(x)(idS.(x)),fieldnames(idS),'un',0);
        appendStr = strjoin(idListC,'_');
        idOut = [filePrefixForHDF5,'_',appendStr];
        
        %Get o/p dirs & dim
        outDirC = getOutputH5Dir(modelInputPath,scanOptS(n),'');
        
        %Write to user-specified model input format
        writeDataForDL(scanC{n},maskC{n},coordInfoS, passedScanDim,inFmt,...
            outDirC,idOut,testFlag);
    end
    
    %Save updated planC file
    tic
    save_planC(planC,[],'PASSED',fileNam);
    toc
end

%% Execute the container

%Get the bind path for the container
bindingDir = ':/scratch';
bindPath = strcat(fullSessionPath,bindingDir);
%Run container app
command = sprintf('singularity run --app %s --nv --bind  %s %s %s', algorithm, bindPath, containerPath, num2str(userOptS.batchSize));
%Print command to stdout
disp('Running container....');
disp(command);
tic
status = system(command);
toc

% Run container app to get git_hash
gitHash = 'unavailable';
[~,hashChk] = system(['singularity exec ' containerPath ' ls /scif/apps | grep get_hash'],'-echo');
if ~isempty(hashChk)
    [~,gitHash] = system(['singularity run --app get_hash ' containerPath],'-echo');
end
roiDescrpt = '';
if isfield(userOptS,'roiGenerationDescription')
    roiDescrpt = userOptS.roiGenerationDescription;
end
roiDescrpt = [roiDescrpt, '  __git_hash:',gitHash];
userOptS.roiGenerationDescription = roiDescrpt;

%% Stack output mask files
fprintf('\nRreading output masks...');
tic
%outC = stackHDF5Files(fullSessionPath,passedScanDim); 
outC = stackDLMaskFiles(fullSessionPath,outFmt,passedScanDim); 
toc

%% Import segmented mask to planC
fprintf('\nImporting to CERR...\n');
tic
identifierS = userOptS.structAssocScan.identifier;
labelPath = fullfile(fullSessionPath,'outputLabelMap');
if ~isempty(fieldnames(userOptS.structAssocScan.identifier))
    origScanNum = getScanNumFromIdentifiers(identifierS,planC);
else
    origScanNum = 1; %Assoc with first scan by default
end
outScanNum = scanNumV(origScanNum);
userOptS.scan(outScanNum) = userOptS.scan(origScanNum);
userOptS.scan(outScanNum).origScan = origScanNum;
success = joinH5CERR(cerrPath,outC{1},labelPath,outScanNum,userOptS); %Updated
toc