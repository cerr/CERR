function [success,origScanNum] = segmentationWrapper(cerrPath,fullSessionPath,...
    containerPath, algorithm, skipMaskExport)
% function success =heart(cerrPath,segResultCERRPath,fullSessionPath,deepLabContainerPath)
%
% This function serves as a wrapper for the all segmentation models
%
% INPUT: 
% cerrPath - path to the original CERR file to be segmented
% fullSessionPath - path to write temporary segmentation metadata.
% deepLabContainerPath - path to the MR Prostate DeepLab V3+ container on the
% algorithm - name of the algorithm to run
% skipMaskExport (optional) - Set to false if model requires segmentation 
%                             masks as input.Default: true.
% 
%
%
% RKP, 5/21/2019
% RKP, 9/11/19 Updates for compatibility with training pipeline

if ~exist('skipMaskExport','var')
    skipMaskExport = true;
end

%Copy config file to session dir
configFilePath = fullfile(getCERRPath,'ModelImplementationLibrary',...
    'SegmentationModels', 'ModelConfigurations', [algorithm, '_config.json']);
copyfile(configFilePath,fullSessionPath);

%% Export data to fmt reqd by model
cmdFlag = 'singcontainer';
planCfiles = dir(fullfile(cerrPath,'*.mat'));
for p=1:length(planCfiles)
    
    % Load plan
    planCfiles(p).name
    fileNam = fullfile(planCfiles(p).folder,planCfiles(p).name);
    planC = loadPlanC(fileNam, tempdir);
    planC = quality_assure_planC(fileNam,planC);
    
    %Pre-process data and export to model input fmt
    [~,command,userOptS,~,scanNumV,planC] = ...
        prepDataForSeg(planC,fullSessionPath,algorithm,cmdFlag,...
        containerPath,[],skipMaskExport);
    
    %Save updated planC file
    tic
    save_planC(planC,[],'PASSED',fileNam);
    toc
    
end

%% Execute the container
disp('Running container....');
%Print command to stdout
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
outFmt = userOptS.modelInputFormat;
passedScanDim = userOptS.passedScanDim;
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