function success = Lung_MRRN(cerrPath,segResultCERRPath,fullSessionPath,deepLabContainerPath)
% function success = Lung_MRRN(cerrPath,segResultCERRPath,fullSessionPath,deepLabContainerPath)
%
% This function serves as a wrapper for the Lung Incremental MRRN Segmentation.
%
% INPUT: 
% cerrPath - path to the original CERR file to be segmented
% segResultCERRPath - path to write CERR RTSTRUCT for resulting segmentation.
% fullSessionPath - path to write temporary segmentation metadata.
% deepLabContainerPath - path to the Lung incremental MRRN container on the
% system
% 
%
%
% RKP, 3/21/2019
    

deepLabContainerPath

cerrToH5(cerrPath, fullSessionPath);

%container_file = fullfile(deepLabContainerPath, '1.sif');
inputH5Path = fullfile(fullSessionPath,'inputH5');

%create subdir within fullSessionPath for h5 files
outputH5Path = fullfile(fullSessionPath,'outputH5');
mkdir(outputH5Path);

command = sprintf('singularity run --nv %s %s %s', deepLabContainerPath, inputH5Path, outputH5Path);
cerrPath
segResultCERRPath
command
status = system(command)

configFilePath = fullfile(getCERRPath,'Contouring','models','incrMRRN','MRRN_config.json');

%return after execution completed
joinH5CERR(segResultCERRPath,cerrPath,outputH5Path,configFilePath);












success = 1;