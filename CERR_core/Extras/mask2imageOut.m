function maskFileNameC = mask2imageOut(planC,scanNum,maskStrC,tmpDirPath,reorientFlag,extn)

if ~exist('tmpDirPath','var') || isempty(tmpDirPath) || ~exist(tmpDirPath,'dir')
    tmpDirPath = fullfile(getCERRPath, 'ImageRegistration', 'tmpFiles');
end

if ~exist('reorientFlag','var') || isempty(reorientFlag)
    reorientFlag = 1;
end

if ~exist('extn','var')
    extn = 'nii';
end

[affineMat,~, voxel_size, mask3MC] = getPlanCAffineMat(planC, scanNum, reorientFlag, maskStrC);
qOffset = affineMat(1:3,end)';

for i = 1:numel(mask3MC)
    mask3M = uint8(mask3MC{i});
    [maskUniqName, ~] = genScanUniqName(planC,scanNum);
    if strcmpi(extn,'nii')
        maskFileNameC{i} = fullfile(tmpDirPath, ['mask_' maskStrC{i} '_' maskUniqName '.nii']);
        vol2nii(mask3M,affineMat,qOffset,voxel_size,maskFileNameC{i});
    end
end