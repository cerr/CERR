function planC_for_XNAT(dicomPath,cerrPath,xhost,xproj,xsubj,xexp, rebuildRS)
% function planC_for_XNAT(dicomPath,cerrPath,xhost,xproj,xsubj,xexp,rebuildRS)
%
% This function imports DICOM files from dicomPath and adds header info
% with XNAT addressing metadata

if ~exist('rebuildRS','var')
    rebuildRS = 0;
end

if strcmpi(rebuildRS,'Y')
    rebuildRS = 1;
end

disp(['importing DICOM from ' dicomPath]);
initFlag = init_ML_DICOM;
importDICOM(dicomPath,cerrPath);

C = dir(fullfile(cerrPath, '*.mat'));
cerrFile = fullfile(C.folder, C.name);

planC = loadPlanC(cerrFile);

planC = annotatePlanCForXNAT(planC, xhost,xexp,xproj,xsubj);

strE = strsplit(xexp,'E');
numExt = str2num(strE{end});

if rebuildRS
    planC = reviveRS(planC,cerrPath,numExt);
end

save_planC(planC,[],'passed',cerrFile);