function [mask,xmesh_new,ymesh_new] = dicomrt_trimZ(slice,voiref,inpmatrix,dose_xmesh,dose_ymesh,voi,voiselect)
% dicomrt_trimZ(slice,voiref,inpmatrix,dose_xmesh,dose_ymesh,voi,voiselect)
%
% Trim a matrix to min and max boundaries in the selected voi along X and Y.
% 
% slice is the number of the section (relative to voiref) to be trimmed.
%   Slice is used to locate the matrix along Z and to match matrix with the corresponding contour in voiselect.
% inpmatrix is a 2D matrix.
% dose_xmesh, dose_ymesh, are the coordinates of the center of the pixel for eval and ref.
% voi and voiselect are the vois' cell array and the # of the voi to be used for the gamma calculation respectively.
%   They have to be specified together. Both matrices will be masked and reduced in size accordingly with the selected
%   voi's dimensions. 
%
% NOTE: Use dicomrt_mask if you want to zeroes all the voxel data outside the voi of interest, without altering the 
%       dimensions of the dose matrix.
%       This function leave unchanged matrix values outside the voi of interest: no mask is performed.
%       This functions changes the X, and Y dimensions of the input matrix to fit as close as possible 
%       to the max and min contour position in x and y direction.
%
% Example:
% 
% [trimdose,new_xmesh,new_ymesh]=dicomrt_trimZ(15,1,dose(:,:,15),dose_xmesh,dose_ymesh,VOI,4);
%
% calculates the position of the maximum and minimum contour for VOI number 4 in x and y and cut from "dose" all
% the voxels positioned outside these boundaries. Returns the new matrix in trimdose, and the new xmesh, ymesh
% in new_xmesh and new_ymesh. Here slice number 15 is defined in voiref 1. 
%
% See also dicomrt_loadmcdose, dicomrt_dosediff
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check case and set-up some parameters and variables
[matrix_temp,type,label,PatientPosition]=dicomrt_checkinput(inpmatrix,1);
matrix=dicomrt_varfilter(matrix_temp);
[voi_temp,type,label]=dicomrt_checkinput(voi);
voi=dicomrt_varfilter(voi_temp);

[locate_voi_min_x,locate_voi_max_x,locate_voi_min_y,locate_voi_max_y] = ...
    dicomrt_voiboundariesZ(slice,voiref,dose_xmesh,dose_ymesh,voi_temp,voiselect,PatientPosition);

mask=matrix(locate_voi_min_y:locate_voi_max_y,locate_voi_min_x:locate_voi_max_x);

xmesh_new=dose_xmesh(locate_voi_min_x:locate_voi_max_x);
ymesh_new=dose_ymesh(locate_voi_min_y:locate_voi_max_y);

% Restore original variable format
[mask]=dicomrt_restorevarformat(matrix_temp,mask);
