function doseFileNameC = dose2imageOut(planC, doseNumV, scanNum, tmpDirPath,reorientFlag,extn)

if ~exist('tmpDirPath','var') || isempty(tmpDirPath) || ~exist(tmpDirPath,'dir')
    tmpDirPath = fullfile(getCERRPath, 'ImageRegistration', 'tmpFiles');
end

if ~exist('reorientFlag','var') || isempty(reorientFlag)
    reorientFlag = 1;
end

if ~exist('extn','var')
    extn = 'nii';
end

[affineMat,~, voxel_size, ~, dose3MC] = getPlanCAffineMat(planC, scanNum, reorientFlag, [], doseNumV);
[~,orientationStr,~] = returnViewerAxisLabels(planC,scanNum);
qOffset = affineMat(1:3,end)';

for i = 1:numel(doseNumV)
    dose3M = dose3MC{i};
    [doseUniqName, ~] = genScanUniqName(planC,scanNum);    
    if strcmpi(extn,'nii')
        doseFileName = fullfile(tmpDirPath, ['dose_' num2str(doseNumV(i)) '_' doseUniqName '.nii']);
        vol2nii(dose3M,affineMat,qOffset,voxel_size,[],doseFileName);
        doseFileNameC{i} = doseFileName;
    elseif strcmpi(extn,'nrrd')
        doseFileName = fullfile(tmpDirPath, ['dose_' num2str(doseNumV(i)) '_' doseUniqName  '.nrrd']);
        vol2nrrd(dose3M,affineMat,qOffset,voxel_size,orientationStr,doseFileName);
        doseFileNameC{i} = doseFileName;
    end
end