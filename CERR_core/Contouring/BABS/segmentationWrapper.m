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
        
% check if any pre-processing is required  
% userInS = jsondecode(fileread(configFilePath)); 
% if sum(strcmp(fieldnames(userInS), 'crop')) == 1
%     cropS = userInS.crop;
% else 
%     cropS = 'None';
% end
% if sum(strcmp(fieldnames(userInS), 'intensityOffset')) == 1
%     intensityOffset = userInS.intensityOffset;
% else 
%     intensityOffset = '';
% end
% if sum(strcmp(fieldnames(userInS), 'resize')) == 1
%     resizeS = userInS.resize;
%     resizeMethod = resizeS.method;
%     outSizeV = userInS.resize.size;
% else
%     resizeS = '';
%     outSizeV = '';
%     resizeMethod = 'None';
% end

% % create subdir within fullSessionPath for output h5 files
outputH5Path = fullfile(fullSessionPath,'outputH5');
mkdir(outputH5Path);

% convert scan to H5 format
%[errC,mask3M,rcsM] = cerrToH5(cerrPath, fullSessionPath, cropS, outSizeV, resizeMethod, intensityOffset);
[userOptS,errC] = prepareSegDataset(configFilePath, inputDicomPath, fullSessionPath); %Updated                  


if ~isempty(errC)
    success = 0;
    return;
end

bindingDir = ':/scratch';
bindPath = strcat(fullSessionPath,bindingDir);
    
% Execute the container
command = sprintf('singularity run --app %s --nv --bind  %s %s %s', algorithm, bindPath, containerPath, fullSessionPath);
status = system(command);

% Stack H5 files
outC = stackHDF5Files(fullClientSessionPath,userOptS.passedScanDim); %Updated


% join segmented mask with planC
success = joinH5CERR(segResultCERRPath,cerrPath,outC{1},userOptS); %Updated
          
