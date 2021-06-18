function [niiC,doseFileNameC] = dose2nii(planC, doseNumV, scanNum, tmpDirPath,reorientFlag)

if ~exist('tmpDirPath','var') || isempty(tmpDirPath) || ~exist(tmpDirPath,'dir')
    tmpDirPath = fullfile(getCERRPath, 'ImageRegistration', 'tmpFiles');
end

if ~exist('reorientFlag','var') || isempty(reorientFlag)
    reorientFlag = 1;
end

[affineMat,~, voxel_size, ~, dose3MC] = getPlanCAffineMat(planC, scanNum, reorientFlag, [], doseNumV);
qOffset = affineMat(1:3,end)';

for i = 1:numel(doseNumV)
    dose3M = dose3MC{i};
    [scanUniqName, ~] = genScanUniqName(planC,scanNum);
    doseFileName = fullfile(tmpDirPath, ['dose_' num2str(doseNumV(i)) '_' scanUniqName '.nii']);
    niiC{i} = vol2nii(dose3M,affineMat,qOffset,voxel_size,doseFileName);
    doseFileNameC{i} = doseFileName;
end