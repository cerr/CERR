function [scanFileNameC,doseFileNameC,maskFileNameC] = ...
    export_scan_dose_struct_from_planC(exportFormat,...
    scanNumV,doseNumV,structNameC,outdDir,planC)
% function [scanFileNameC,doseFileNameC,maskFileNameC] = ...
%     export_scan_dose_struct_from_planC(exportFormat,...
%     scanNumV,doseNumV,structNameC,outNrrdDir,planC)
%
% exportFormat: nii or nrrd
% scanNumV: indices of scans in planC to export
% doseNumV: indices of doses in planC to export
% structNameC: cell array of structure names to export
% outDir: directory to export to
% planC:
%
% APA, 9/13/2021

indexS = planC{end};
reorientFlag = 1;
dataType = [];

scanFileNameC = {};
doseFileNameC = {};
maskFileNameC = {};

% scan
for iScan = 1:length(scanNumV)
    scanNum = scanNumV(iScan);
    scanFileNameC = scan2imageOut(planC,scanNumV,outdDir,reorientFlag,exportFormat,dataType);
end

% dose
for iDose = 1:length(doseNumV)
    doseNum = doseNumV(iDose);
    scanNum = getDoseAssociatedScan(doseNum,planC);
    doseFileNameC = dose2imageOut(planC, doseNumV, scanNum, outdDir,reorientFlag,exportFormat);
end

% structure
maskFileNameC = mask2imageOut(planC,scanNum,structNameC,outdDir,reorientFlag,exportFormat);
