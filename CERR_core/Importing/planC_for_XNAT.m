function planC_for_XNAT(dicomPath,cerrPath,xhost,xproj,xsubj,xexp)
% function planC_for_XNAT(dicomPath,cerrPath,xhost,xproj,xsubj,xexp)
%
% This function imports DICOM files from dicomPath and adds header info
% with XNAT addressing metadata

importDICOM(dicomPath,cerrPath);

cerrFile = ls([cerrPath filesep '*.mat']);

%cerrFilePath = [cerrPath filesep cerrFile];

load(cerrFile(1:end-1),'planC');

planC = annotatePlanCForXNAT(planC, xhost,xexp,xproj,xsubj);

save(cerrFile,'planC');