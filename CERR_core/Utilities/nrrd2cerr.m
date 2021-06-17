function planC = nrrd2cerr(filename,scanName,planC,save_flag)
% nii2cerr.m
% http://teem.sourceforge.net/nrrd/format.html#space
% 
% Import .nrrd data to CERR
% Usage: planC = nrrd2cerr(filename,scanName,planC,save_flag);
%
% AI 4/10/19 for nii
% EL 06/17/21 adapt for nrrd

if ~exist('planC','var') || isempty(planC)
    planC = [];
end

if ~exist('save_flag','var') || isempty(save_flag)
    save_flag = 0;
end

% read nrrd file
% [vol3M,infoS] = nifti_read_volume(filename);
% nii = load_nii(filename);
headerInfo = nhdr_nrrd_read(filename,1);

% vol3M = nii.img;
vol3M = headerInfo.data;
infoS.Offset = [headerInfo.spaceorigin(1) headerInfo.spaceorigin(2) headerInfo.spaceorigin(3)];
infoS.PixelDimensions = [abs(headerInfo.spacedirections_matrix(1,1)) abs(headerInfo.spacedirections_matrix(2,2)) abs(headerInfo.spacedirections_matrix(3,3))];
infoS.Dimensions = headerInfo.sizes;

scanOffset = 0;
volMin = min(vol3M(:));
if volMin<0
    scanOffset = -volMin;
end

if headerInfo.spacedirections_matrix(1,1) > 0
    vol3M = flip(vol3M,1);
end

if headerInfo.spacedirections_matrix(2,2) > 0
    vol3M = flip(vol3M,2);
end

% infoS.Offset = [0 0 0];
% infoS.PixelDimensions = infoS.pixdim;
% infoS.Dimensions = infoS.dimension(2:4);

planC = mha2cerr(infoS,vol3M,scanOffset,scanName,planC,save_flag);


end