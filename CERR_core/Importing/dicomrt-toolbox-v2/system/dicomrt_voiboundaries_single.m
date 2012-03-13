function [locate_voi_min_1,locate_voi_max_1,locate_voi_min_2,locate_voi_max_2] = dicomrt_voiboundaries_single(slice,dose_1mesh,dose_2mesh,VOI,voi2use,PatientPosition)
% dicomrt_voiboundaries_single(slice,dose_1mesh,dose_2mesh,VOI,voi2use,PatientPosition)
%
% Returns the voxel index of the smallest and largest coordinate of the selected VOI in the specified Z slice.
%
% slice is the slice number where the mins and maxs will be calculated.
%      Slice number is relative to the selected voi.
% dose_1mesh,dose_2mesh, are coordinates of the center of the dose-pixel 
% VOI is a cell array which contain the patients VOIs as read by dicomrt_loadvoi
% voi2use is a vector pointing to the number of VOIs to be used 
%
%
% See also dicomrt_voiboundaries, dicomrt_surfdose
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check input
[VOI_temp]=dicomrt_checkinput(VOI);
VOI=dicomrt_varfilter(VOI_temp);

% calculating parameters
min_1=min(dose_1mesh);
pixel_spacing_1=abs(dose_1mesh(2)-dose_1mesh(1));
max_1=max(dose_1mesh);

min_2=min(dose_2mesh);
pixel_spacing_2=abs(dose_2mesh(2)-dose_2mesh(1));
max_2=max(dose_2mesh);

% locate VOI boundaries
ncont=size(VOI{voi2use,2},1); % number of countour slices for voi2use 

index1=1;
index2=2;

voi_min_1=min(VOI{voi2use,2}{slice}(:,index1));
voi_max_1=max(VOI{voi2use,2}{slice}(:,index1));
voi_min_2=min(VOI{voi2use,2}{slice}(:,index2));
voi_max_2=max(VOI{voi2use,2}{slice}(:,index2));

% Create boundaries
dose_1mesh_grid=dicomrt_createboundgrid(dose_1mesh);
dose_2mesh_grid=dicomrt_createboundgrid(dose_2mesh);

if PatientPosition==1
    locate_voi_min_1=dicomrt_findpointVECT(dose_1mesh_grid,voi_min_1);
    locate_voi_max_1=dicomrt_findpointVECT(dose_1mesh_grid,voi_max_1);
    locate_voi_min_2=dicomrt_findpointVECT(dose_2mesh_grid,voi_min_2);
    locate_voi_max_2=dicomrt_findpointVECT(dose_2mesh_grid,voi_max_2);
elseif PatientPosition==2
    locate_voi_min_1=dicomrt_findpointVECT(dose_1mesh_grid,voi_min_1);
    locate_voi_max_1=dicomrt_findpointVECT(dose_1mesh_grid,voi_max_1);
    locate_voi_min_2=dicomrt_findpointVECT(dose_2mesh_grid,voi_min_2);
    locate_voi_max_2=dicomrt_findpointVECT(dose_2mesh_grid,voi_max_2);
elseif PatientPosition==3
    dose_1mesh=flipdim(dose_1mesh,1);
    dose_2mesh=flipdim(dose_2mesh,1);
    locate_voi_max_1=length(dose_1mesh)-dicomrt_findpointVECT(dose_1mesh_grid,voi_min_1);
    locate_voi_min_1=length(dose_1mesh)-dicomrt_findpointVECT(dose_1mesh_grid,voi_max_1);
    locate_voi_max_2=length(dose_2mesh)-dicomrt_findpointVECT(dose_2mesh_grid,voi_min_2);
    locate_voi_min_2=length(dose_2mesh)-dicomrt_findpointVECT(dose_2mesh_grid,voi_max_2);
elseif PatientPosition==4
    dose_1mesh=flipdim(dose_1mesh,1);
    dose_2mesh=flipdim(dose_2mesh,1);
    locate_voi_max_1=length(dose_1mesh)-dicomrt_findpointVECT(dose_1mesh_grid,voi_min_1);
    locate_voi_min_1=length(dose_1mesh)-dicomrt_findpointVECT(dose_1mesh_grid,voi_max_1);
    locate_voi_max_2=length(dose_2mesh)-dicomrt_findpointVECT(dose_2mesh_grid,voi_min_2);
    locate_voi_min_2=length(dose_2mesh)-dicomrt_findpointVECT(dose_2mesh_grid,voi_max_2);
else
    error('dicomrt_voiboundaries_single: Unable to parse PatientPosition. Exit now!');
end

% Some VOI may be defined outside the patient outline.
% Therefore some of the points may lie outside the density matrix limits.
% This may result in an empty locate_voi. Let's fix it.
if isempty(locate_voi_min_1)==1
    locate_voi_min_1=1;
end
if isempty(locate_voi_max_1)==1
    locate_voi_max_1=length(dose_1mesh);
end
if isempty(locate_voi_min_2)==1
    locate_voi_min_2=1;
end
if isempty(locate_voi_max_2)==1
    locate_voi_max_2=length(dose_2mesh);
end
