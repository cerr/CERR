function [GVH] = dicomrt_gvhcal(VOI,gamma,gamma_xmesh,gamma_ymesh,gamma_zmesh,gvhselect,xgrid)
% dicomrt_gvhcal(VOI,gamma,gamma_xmesh,gamma_ymesh,gamma_zmesh,gvhselect,xgrid)
%
% Calculate GAMMA-VOLUME-HISTOGRAMS for VOIs and cell_case_study. Light Version.
% This function calculate GVHs for all the available VOIs or for a selected number of them.
%
% gamma contains the 3D gamma map
% gamma_xmesh,gamma_ymesh,gamma_zmesh are x-y-z coordinates of the center of the gamma-voxels 
% VOIs        cell array and contains all the Volumes of Interest
% gvhselect   number corresponding to the VOI to calculate GVHs for
% xgrid       OPTIONAL parameter that sets the resolution for GVH
%             calculation. If not set a default grid is used with a
%             resolution of 0.1 for GAMMA values between 0 and 1.
%
%
% GVHs are stored in a cell array with the following structure:
%
%  --------------------------------
%  | [GVH-name] | [3D gamma mask] |
%  |            -------------------
%  |            | [gvh data]      |
%  |            -------------------
%  |            | VOI volume      | 
%  |            -------------------
%  |            | Voxel volume    | 
%  --------------------------------
%
% [gvh data] is a 2 columns vector with following structure:
%
% ----------------------
% | gamma grid | count |
% ----------------------
% |            |       |
% |            |       |
% |            |       |
% |            |       |
% ----------------------
%
%
% Example:
%
% gvh=dicomrt_gvhcal(VOI,gamma,gamma_xmesh,gamma_ymesh,gamma_zmesh,4) returns 
% the GVH for the VOI number 4 in VOI and the gamma distribution stored in the 
% 3D matrix 'gamma'.
%
% See also dicomrt_loaddose, roifilt2, roipoly, dicomrt_gvhplot, dicomrt_GAMMAcal2D
%           
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check number of argument and set-up some parameters and variables
error(nargchk(6,7,nargin))

% Check voi
% Check case and set-up some parameters and variables
[gamma_temp,type,label,PatientPosition]=dicomrt_checkinput(gamma);
gamma=dicomrt_varfilter(gamma_temp);
[VOI_temp]=dicomrt_checkinput(VOI);
VOI=dicomrt_varfilter(VOI_temp);

% Define xgrid
if exist('xgrid')~=1
    xgrid=[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.2 1.4 1.6 1.8 2.0 ...
            3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0 Inf];
end

% Define cell array
GVH=cell(1,2);
GVH{1,1}=['GVH-',VOI{gvhselect,1}];

% Calculate voxel volume
[voxelvolume, status]=dicomrt_voxelvolumecal(gamma_temp,gamma_xmesh,gamma_ymesh,gamma_zmesh);
volume_VOI_check=[];

disp(['GVH calculation for VOI: ',VOI{gvhselect,1}]);
% mask gamma matrix with current VOI
[mask_VOI_temp,volume_VOI,mask4VOI]=dicomrt_mask(VOI_temp,gamma_temp,gamma_xmesh,gamma_ymesh,gamma_zmesh,gvhselect,'nan','n');
mask_VOI=dicomrt_varfilter(mask_VOI_temp);
if status==0
    vgrid=histc(reshape(mask_VOI,1,size(mask_VOI,1)*size(mask_VOI,2)*size(mask_VOI,3)),xgrid);
    % get back voxels with dose<min(xgrid) cause histc does not
    % account for it
    temp_min=find(mask_VOI<xgrid(1) & mask_VOI~=0);
    if isempty(temp_min)~=1
        vgrid(1)=vgrid(1)+length(temp_min);
    end
    vgrid=vgrid.*voxelvolume(1);
    temp2=cumsum(vgrid);
    volume_VOI_check=[volume_VOI_check,temp2(end)];
else
    vgrid=zeros(length(dosegrid),1);
    for i=1:size(mask_VOI,3)
        temp_vgrid=histc(reshape(mask_VOI(:,:,i),1,size(mask_VOI(:,:,i),1)*size(mask_VOI(:,:,i),2)),xgrid);
        % get back voxels with dose<min(xgrid) cause histc does not
        % account for it
        temp_min=find(mask_VOI(:,:,i)<xgrid(1) & mask_VOI~=0);
        if isempty(temp_min)~=1
            temp_vgrid(1)=temp_vgrid(1)+length(temp_min);
        end
        vgrid=vgrid+temp_vgrid'.*voxelvolume(i);
    end
    temp2=cumsum(vgrid);
    volume_VOI_check=[volume_VOI_check,temp2(end)];
end
    
if isempty(vgrid)~=1    
    if dicomrt_mmdigit(volume_VOI,7)~=dicomrt_mmdigit(volume_VOI_check,7)
        warning(['dicomrt_gvhcal: volume VOI for: ',VOI{gvhselect,1},' and length(gamma_VOI) does not match. This should not happen.']);
        disp(['volume VOI: ',num2str(volume_VOI),' was replaced with: ', num2str(volume_VOI_check)]);
        volume_VOI=volume_VOI_check;
    end
    % Inf value will won't be plotted in the x grid. Therefore we
    % collect all the Inf values in the last slot of xgrid/vgrid
    vgrid(end-1)=vgrid(end-1)+vgrid(end);
    vgrid(end)=[];
    xgrid(end)=[];
    % calculate GVH
    gvhdata=[dicomrt_makevertical(xgrid),dicomrt_makevertical(vgrid)];
    % store data in cell array
    GVH{1,2}{1,1}=mask_VOI;
    GVH{1,2}{2,1}=gvhdata;
    GVH{1,2}{3,1}=volume_VOI;
    % plot frequency GVH
    figure;
    if isempty(inputname(2))==1
        set(gcf,'Name',['dicomrt_gvhcal: ','fGVH for ',inputname(1)]);
    else
        set(gcf,'Name',['dicomrt_gvhcal: ','fGVH for ',inputname(2)]);
    end
    bar(xgrid,vgrid);
    title(VOI{gvhselect,1},'Fontsize', 18);
    xlabel('GAMMA','Fontsize', 14);
    ylabel('Volume [cc]','Fontsize', 14);
    clear mask_VOI volume_VOI new_volume_VOI mask4VOI vgrid gamma_VOI
 else
    warning(['dicomrt_gvhcal: GVH is null for this VOI: ',GVH{k,1}]);
    gvhdata=[0,0];
    GVH{1,2}{1,1}=mask_VOI;
    GVH{1,2}{2,1}=gvhdata;
    GVH{1,2}{3,1}=volume_VOI;
    clear mask_VOI volume_VOI new_volume_VOI mask4VOI vgrid gamma_VOI
end
