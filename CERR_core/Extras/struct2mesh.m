function [faces,vertices] = struct2mesh(mask3M,stlfile,qOffset,voxel_size)
% 
% nii = load_untouch_nii(niifile);
% logicalmask = zeros(size(nii.img));
% logicalmask(find(nii.img)) = 1;

if nargin < 4 || ~exist('voxel_size','var') || isempty(voxel_size)
    voxel_size = [1 1 1];
end

if nargin < 3 || ~exist('qOffset','var') || isempty(qOffset)
    sz3M = size(mask3M);
    qOffset = -[voxel_size(1)*sz3M(1) voxel_size(2)*sz3M(2) voxel_size(3)*sz3M(3)]/2;
end

logicalmask = flip(flip(mask3M,1),2);

gridX =voxel_size(1)* [1:size(logicalmask,1)]  + qOffset(1);
gridY = voxel_size(2)*[1:size(logicalmask,2)] + qOffset(2);
gridZ = voxel_size(3)*[1:size(logicalmask,3)] + qOffset(3);

[faces,vertices] = CONVERT_voxels_to_stl(stlfile,logicalmask,gridX,gridY,gridZ,'binary');