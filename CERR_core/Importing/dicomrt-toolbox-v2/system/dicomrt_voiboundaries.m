function [locate_voi_min_x,locate_voi_max_x,locate_voi_min_y,locate_voi_max_y,locate_voi_min_z,locate_voi_max_z] = dicomrt_voiboundaries(dose_xmesh,dose_ymesh,dose_zmesh,VOI,voi2use,PatientPosition)
% dicomrt_voiboundaries(dose_xmesh,dose_ymesh,dose_zmesh,VOI,voi2use,PatientPosition)
%
% Returns the voxel index of the smallest and largest coordinate of the selected VOI in the specified Z slice.
%
% slice is the slice number where the mins and maxs will be calculated.
%      Slice number is relative to voiref.
% voiref is the voi of reference
% dose_xmesh,dose_ymesh, are coordinates of the center of the dose-pixel 
% VOI is a cell array which contain the patients VOIs as read by dicomrt_loadvoi
% voi2use is a vector pointing to the number of VOIs to be used 
%
% Example:
%
% [xmin,xmax,ymin,ymax]=dicomrt_voiboundariesZ(12,1,xmesh,xmesh,VOI,5)
%
% returns in xmin,xmax,ymin,ymax the pixel numbers which correspond to the edges of 
% structure "5" (e.g. target) in slice number 12 with reference to structure number "1".
%
% See also dicomrt_voiboundaries, dicomrt_surfdose
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check input
[VOI_temp]=dicomrt_checkinput(VOI);
VOI=dicomrt_varfilter(VOI_temp);

nslices=size(VOI{voi2use,2},1);

voiref=1;

for kk=1:nslices
    [locate_voi_min_1,locate_voi_max_1,locate_voi_min_2,locate_voi_max_2]=dicomrt_voiboundaries_single(kk,dose_xmesh,dose_ymesh,VOI_temp,voi2use,PatientPosition);
    if kk==1
        locate_voi_min_x=locate_voi_min_1;
        locate_voi_max_x=locate_voi_max_1;
        locate_voi_min_y=locate_voi_min_2;
        locate_voi_max_y=locate_voi_max_2;
    else
        if locate_voi_min_1 < locate_voi_min_x
            locate_voi_min_x=locate_voi_min_1;
        end
        if locate_voi_max_1 > locate_voi_max_x
            locate_voi_max_x=locate_voi_max_1;
        end
        if locate_voi_min_2 < locate_voi_min_y
            locate_voi_min_y=locate_voi_min_2;
        end
        if locate_voi_max_2 > locate_voi_max_y
            locate_voi_max_y=locate_voi_max_2;
        end
    end
end

% z mesh is always sorted
min_z_voi=VOI_temp{2,1}{voi2use,2}{1}(1,3);
max_z_voi=VOI_temp{2,1}{voi2use,2}{end}(1,3);

locate_voi_min_z=dicomrt_findpointVECT(dose_zmesh,min_z_voi);
locate_voi_max_z=dicomrt_findpointVECT(dose_zmesh,max_z_voi);
        