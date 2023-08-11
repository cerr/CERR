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
[~,orientationStr,~] = returnViewerAxisLabels(planC,scanNum);

qOffset = affineMat(1:3,end)';

structNameC = {};
if isnumeric(maskStrC)
    indexS = planC{end};
    for i = 1:length(maskStrC)
        structNameC{i} = planC{indexS.structures}(maskStrC(i)).structureName;
    end
else
    structNameC = maskStrC;
end

for i = 1:numel(mask3MC)
    mask3M = uint8(mask3MC{i});
    if isempty(mask3M)
        maskFileNameC{i} = '';
        continue;
    end
    [maskUniqName, ~] = genScanUniqName(planC,scanNum);
    if strcmpi(extn,'nii')
        maskFileNameC{i} = fullfile(tmpDirPath, ['mask_' structNameC{i} '_' maskUniqName '.nii']);
        vol2nii(mask3M,affineMat,qOffset,voxel_size,[],maskFileNameC{i});
    elseif strcmpi(extn,'nrrd')
        maskFileNameC{i} = fullfile(tmpDirPath, ['mask_' structNameC{i} '_' maskUniqName '.nrrd']);
        vol2nrrd(mask3M,affineMat,qOffset,voxel_size,orientationStr,maskFileNameC{i});
    end
end
