function success = segmentationWrapper(inputDicomPath,cerrPath,segResultCERRPath,fullSessionPath, containerPath, algorithm)
% function success =heart(cerrPath,segResultCERRPath,fullSessionPath,deepLabContainerPath)
%
% This function serves as a wrapper for the all segmentation models
%
% INPUT: 
% cerrPath - path to the original CERR file to be segmented
% segResultCERRPath - path to write CERR RTSTRUCT for resulting segmentation.
% fullSessionPath - path to write temporary segmentation metadata.
% deepLabContainerPath - path to the MR Prostate DeepLab V3+ container on the
%algorithm - name of the algorithm to run
% system
% 
%
%
% RKP, 5/21/2019
% RKP, 9/11/19 Updates for compatibility with training pipeline

containerPath
algorithm


%build config file path from algorithm
configFilePath = fullfile(getCERRPath,'ModelImplementationLibrary','SegmentationModels', 'ModelConfigurations', [algorithm, '_config.json']);
testFlag = true;

% % create subdir within fullSessionPath for output h5 files
outputH5Path = fullfile(fullSessionPath,'outputH5');
mkdir(outputH5Path);
%create subdir within fullSessionPath for input h5 files
inputH5Path = fullfile(fullSessionPath,'inputH5');
mkdir(inputH5Path);


%get the planC
planCfiles = dir(fullfile(cerrPath,'*.mat'));
for p=1:length(planCfiles)
    
    % Load scan
    planCfiles(p).name
    fileNam = fullfile(planCfiles(p).folder,planCfiles(p).name);
    planC = loadPlanC(fileNam, tempdir);
    planC = quality_assure_planC(fileNam,planC);
    
    % convert scan to H5 format
    userOptS = readDLConfigFile(configFilePath);
   
    [scanC, mask3M] = extractAndPreprocessDataForDL(userOptS,planC,testFlag);
    %Note: mask3M is empty for testing
    filePrefixForHDF5 = 'cerrFile';
    writeHDF5ForDL(scanC,mask3M,userOptS.passedScanDim,inputH5Path,filePrefixForHDF5,testFlag);

end

%get the bind path for the container
bindingDir = ':/scratch';
bindPath = strcat(fullSessionPath,bindingDir);
 
%execute the container
command = sprintf('singularity run --app %s --nv --bind  %s %s %s %s', algorithm, bindPath, containerPath, num2str(userOptS.batchSize));
status = system(command);

% Stack H5 files
outC = stackHDF5Files(fullSessionPath,userOptS.passedScanDim); %Updated

% join segmented mask with planC
success = joinH5CERR(segResultCERRPath,cerrPath,outC{1},userOptS); %Updated
          
