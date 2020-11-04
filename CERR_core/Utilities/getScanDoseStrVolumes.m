function [scan3M,dose3M,strMaskC,xyzGridC,strColorC] = ...
    getScanDoseStrVolumes(scanNum,doseNum,structNamC,planC)
% function [scan3M,dose3M,strMaskC] = ...
% getScanDoseStr(scanNum,doseNum,structnamC,planC)
%
% This function returns volumetric matrices for scan, dose and structure 
% masks on the original scan grid.
%
% Example usage
% cerrFileName = 'L:\Data\RTOG0617\CERR_files_tcia_registered_0617-489880_09-09-2000-50891\0617-489880_09-09-2000-50891.mat';
% scanNum = 1;
% doseNum = 1;
% structNamC = {'DL_HEART_MT','DL_AORTA','DL_LA','DL_LV','DL_RA',...
%       'DL_RV','DL_IVC','DL_SVC','DL_PA'};
% 
% % Load planC from file
% planC = loadPlanC(cerrFileName,tempdir);
% planC = updatePlanFields(planC);
% planC = quality_assure_planC(cerrFileName,planC);
% % Get scan,dose, struct volumes
% [scan3M,dose3M,strMaskC] = getScanDoseStr(scanNum,doseNum,structnamC,planC);
%
% APA, 11/2/2020

indexS = planC{end};

% Extract scan grid
[xValsV, yValsV, zValsV] = getScanXYZVals(planC{indexS.scan}(1));
xyzGridC = {xValsV, yValsV, zValsV};

% Extract scan
scan3M = double(planC{indexS.scan}(scanNum).scanArray);
ctOffset = double(planC{indexS.scan}(scanNum).scanInfo(1).CTOffset);
scan3M = scan3M - ctOffset;

% Extract Dose on scan grid
scanType = 'normal';
dose3M = getDoseOnCT(doseNum, scanNum, scanType, planC);

% Extract structure
numStructs = length(structNamC);
strC = {planC{indexS.structures}.structureName};
strMaskC = cell(1,numStructs);
strColorC = cell(1,numStructs);
for iStr = 1:numStructs
    strNum = getMatchingIndex(structNamC{iStr},strC,'exact');
    strMask3M = getStrMask(strNum,planC);
    strMaskC{iStr} = strMask3M;
    strColorC{iStr} = planC{indexS.structures}(strNum).structureColor;
end

