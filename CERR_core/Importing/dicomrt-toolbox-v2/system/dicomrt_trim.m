function [mask,xmesh_new,ymesh_new,zmesh_new] = dicomrt_trim(inpmatrix,dose_xmesh,dose_ymesh,dose_zmesh,voi,voiselect)
% dicomrt_trim(inpmatrix,dose_xmesh,dose_ymesh,dose_zmesh,voi,voiselect)
%
% Trim a matrix to min and max boundaries in the selected voi along X Y and Z.
% 
% inpmatrix contains the 3D matrix that will be trimmed
% dose_xmesh, dose_ymesh, are the coordinates of the center of the voxels
% voi and voiselect are the vois' cell array and the # of the voi to be used for the gamma calculation respectively.
%   They have to be specified together. Both matrices will be masked and reduced in size accordingly with the selected
%   voi's dimensions. 
%
% NOTE: Use dicomrt_mask if you want to zeroes all the voxel data outside the voi of interest, without altering the 
%       dimensions of the dose matrix.
%       This function leave unchanged matrix values outside the voi of interest: no mask is performed.
%       This functions changes the X, Y and Z dimensions of the input matrix to fit as close as possible 
%       to the max and min contour position in x, y and z direction.
%
% Example:
% 
% [trimdose,new_xmesh,new_ymesh,new_zmesh]=dicomrt_trim(dose,dose_xmesh,dose_ymesh,dose_zmesh,VOI,4);
%
% calculates the position of the maximum and minimum contour for VOI number 4 in z, y and z and cut from "dose" all
% the voxels positioned outside these boundaries. Returns the new matrix in trimdose, and the new xmesh, ymesh, zmesh
% in new_xmesh,new_ymesh,new_zmesh.
%
% See also dicomrt_loadmcdose, dicomrt_dosediff
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check case and set-up some parameters and variables
[matrix_temp,type,label]=dicomrt_checkinput(inpmatrix,1);
matrix=dicomrt_varfilter(matrix_temp);
[voi_temp,type,label]=dicomrt_checkinput(voi);
voi=dicomrt_varfilter(voi_temp);

[locate_voi_min_x,locate_voi_max_x,locate_voi_min_y,locate_voi_max_y,locate_voi_min_z,locate_voi_max_z] = ...
    dicomrt_voiboundaries(dose_xmesh,dose_ymesh,dose_zmesh,voi_temp,voiselect);

mask=matrix(locate_voi_min_y:locate_voi_max_y,locate_voi_min_x:locate_voi_max_x,...
    locate_voi_min_z:locate_voi_max_z);

xmesh_new=dose_xmesh(locate_voi_min_x:locate_voi_max_x);
ymesh_new=dose_ymesh(locate_voi_min_y:locate_voi_max_y);
zmesh_new=dose_zmesh(locate_voi_min_z:locate_voi_max_z);

% Restore original variable format
[mask]=dicomrt_restorevarformat(matrix_temp,mask);
