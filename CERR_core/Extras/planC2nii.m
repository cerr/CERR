function [nii, scanFileName] = planC2nii(planC,scanNumV,tmpDirPath)

if ~exist('tmpDirPath','var') || isempty(tmpDirPath) || ~exist(tmpDirPath,'dir')
    tmpDirPath = fullfile(getCERRPath, 'ImageRegistration', 'tmpFiles');
%     [scanUniqName, ~] = genScanUniqName(planC,scanNum);
%     scanFileName = fullfile(tmpDirPath, ['scan_' scanUniqName '.nii']);
% elseif exist(scanFileName,'dir')
%     [scanUniqName, ~] = genScanUniqName(planC,scanNum);
%     scanFileName = fullfile(scanFileName, ['scan_' scanUniqName '.nii']);
end

[affineMat,scan3M_RAS,voxel_size] = getScanAffineMat(planC, scanNum, 1);

qOffset = affineMat(1:3,end);

nii = make_nii(scan3M_RAS,voxel_size, qOffset); 

% nii.untouch  = 1;

nii.hdr.hist.srow_x = affineMat(1,:);
nii.hdr.hist.srow_y = affineMat(2,:);
nii.hdr.hist.srow_z = affineMat(3,:);
nii.hdr.hist.qoffset_x = qOffset(1);
nii.hdr.hist.qoffset_y = qOffset(2);
nii.hdr.hist.qoffset_z = qOffset(3);
nii.hdr.hist.qform_code = 1;
nii.hdr.hist.sform_code = 1;

save_nii(nii,scanFileName);