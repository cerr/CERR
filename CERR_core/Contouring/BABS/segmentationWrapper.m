function success = segmentationWrapper(cerrPath,segResultCERRPath,fullSessionPath, containerPath, algorithm)
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

containerPath
algorithm

%build config file path from algorithm
configFilePath = fullfile(getCERRPath,'ModelImplementationLibary','SegmentationModels', 'ModelConfigurationFiles', [algorithm, '_config.json']);
        
% check if any pre-processing is required  
userInS = jsondecode(fileread(configFilePath)); 
userInS = jsondecode(fileread(configFilePath)); 
if sum(strcmp(fieldnames(userInS), 'crop')) == 1
    cropS = userInS.crop;
else 
    cropS = '';
end
if sum(strcmp(fieldnames(userInS), 'imageSizeForModel')) == 1
    outSizeV = userInS.imageSizeForModel;
else
    outSizeV = '';
end

if sum(strcmp(fieldnames(userInS), 'resize')) == 1
    resizeS = userInS.resize;
else
    resizeS = '';
end

% convert scan to H5 format
errC = cerrToH5(cerrPath, fullSessionPath, cropS, outSizeV, resizeS);

if ~isempty(errC)
    success = 0;
    return;
end

% % create subdir within fullSessionPath for output h5 files
outputH5Path = fullfile(fullSessionPath,'outputH5');
mkdir(outputH5Path);

bindingDir = ':/scratch'
bindPath = strcat(fullSessionPath,bindingDir)
    
% Execute the container
command = sprintf('singularity run --app %s --nv --bind  %s %s %s', algorithm, bindPath, containerPath, fullSessionPath)
status = system(command)


% join segmented mask with planC
success = joinH5CERR(segResultCERRPath,cerrPath,outputH5Path,algorithm);
