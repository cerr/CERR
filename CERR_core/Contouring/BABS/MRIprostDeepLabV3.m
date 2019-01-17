function success = MRIprostDeepLabV3(cerrPath,segResultCERRPath,fullSessionPath,deepLabContainerPath,outputDicomPath)
%function success = MRIprostDeepLabV3(cerrPath,segResult,fullSessionPath,deepLabModelPath)
% INPUT: 
% inputDicomPath - path to input DICOM directory which needs to be segmented.
% outputDicomPath - path to write DICOM RTSTRUCT for resulting segmentation.
% sessionPath - path to write temporary segmentation metadata.
    %here generate h5 files and save them to session directory
    %make system call to the container, location of which is in the
    %deepLabModelPath arg
    %masks are saved to segResultCERRPath
    %function to join masks with planC
    %call existing function exportCERRtoDICOM.m to export DICOM

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

%return after execution completed
joinH5CERR(segResultCERRPath,cerrPath,outputH5Path,outputDicomPath);












success = 1;