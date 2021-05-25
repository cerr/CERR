function [niiC, scanFileNameC] = scan2nii(planC,scanNumV,tmpDirPath,reorientFlag)

if ~exist('tmpDirPath','var') || isempty(tmpDirPath) || ~exist(tmpDirPath,'dir')
    tmpDirPath = fullfile(getCERRPath, 'ImageRegistration', 'tmpFiles');
end

if ~exist('reorientFlag','var') || isempty(reorientFlag)
    reorientFlag = 1;
end

for i = 1:numel(scanNumV)
    scanNum = scanNumV(i);
    [scanUniqName, ~] = genScanUniqName(planC,scanNum);
    [affineMat,scan3M_RAS,voxel_size] = getPlanCAffineMat(planC, scanNum, 1);
    qOffset = affineMat(1:3,end)';
    scanFileName = fullfile(tmpDirPath, ['scan_' num2str(scanNumV(i)) '_' scanUniqName '.nii']);
    niiC{i} = vol2nii(scan3M_RAS,affineMat,qOffset,voxel_size,scanFileName);
    scanFileNameC{i} = scanFileName;
end
