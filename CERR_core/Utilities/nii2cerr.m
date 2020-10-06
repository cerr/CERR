function planC = nii2cerr(filename,scanName,planC,save_flag)
% nii2cerr.m
%
% Import .nii data to CERR
% Usage: planC = nii2cerr(filename,scanName,planC,save_flag);
%
% AI 4/10/19


if ~exist('planC','var') || isempty(planC)
    planC = [];
end

[vol3M,infoS] = nifti_read_volume(filename);
scanOffset = 0;
volMin = min(vol3M(:));
if volMin<0
    scanOffset = -volMin;
end
infoS.Offset = [0 0 0];
infoS.PixelDimensions = infoS.pixdim;
infoS.Dimensions = infoS.dimension(2:4);
planC = mha2cerr(infoS,vol3M,scanOffset,scanName,planC,save_flag);

end