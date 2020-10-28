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

%% Create directories to write input, output h5 files
outputH5Path = fullfile(fullSessionPath,'outputH5');
mkdir(outputH5Path);
inputH5Path = fullfile(fullSessionPath,'inputH5');
mkdir(inputH5Path);

%Read config file
userOptS = readDLConfigFile(configFilePath);

%% Export data to H5
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
    [scanC, maskC, scanNumV, userOptS, planC] = ...
        extractAndPreprocessDataForDL(userOptS,planC,testFlag);
    %Note: mask3M is empty in inference mode
    toc
    
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
tic
status = system(command);
toc

%% Stack H5 files
fprintf('\nRreading output masks...');
tic
outC = stackHDF5Files(fullSessionPath,userOptS.passedScanDim); %Updated
toc

%% Import segmented mask to planC
fprintf('\nImporting to CERR...\n');
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
success = joinH5CERR(cerrPath,outC{1},outScanNum,userOptS); %Updated
toc
          
