function [DVH,volume_VOI_first,volume_VOI_check] = dicomrt_dvhcal(VOI,study,dose_xmesh,dose_ymesh,dose_zmesh,dvhselect)
% dicomrt_dvhcal(VOI,study,dose_xmesh,dose_ymesh,dose_zmesh,dvhselect)
%
% Calculate DOSE-VOLUME-HISTOGRAMS for VOIs and cell_case_study.
% This function calculate DVHs for all the available VOIs or for a selected number of them.
%
% study is the RTPLAN or the MC generated dataset containing the dose matrix
% ct is the CT dataset
% dose_xmesh,dose_ymesh,dose_zmesh are x-y-z coordinates of the center of the dose-voxels 
% VOIs is a cell array and contains all the Volumes of Interest
% dvhselect is an OPTIONAL vector which contains the number of VOI to calculate DVHs for.
%
% NOTE: if dvhselect is omitted DVHs are calculated for all the VOIs
%
% DVHs are stored in a cell array with the following structure:
%
%  -----------------------------
%  | [DVH 1] | [3D dose mask]  |
%  |         -------------------
%  |         | [dvh data]      |
%  |         -------------------
%  |         | VOI volume      | 
%  |         -------------------
%  |         | Voxel volume    | 
%  -----------------------------
%  |   ...   |     ...         |  
%  -----------------------------
%  | [DVH n] | [3D dose mask]  |
%  |         -------------------
%  |         | [dvh data]      |
%  |         -------------------
%  |         | VOI volume      | 
%  |         -------------------
%  |         | Voxel volume    | 
%  -----------------------------
%
% [dvh data] is a 2 columns vector with following structure:
%
% -----------------
% | dose | volume |
% | (Gy) |  (cc)  |
% -----------------
% |      |        |
% |      |        |
% |      |        |
% |      |        |
% -----------------
%
%
% Example:
%
% dvh=dicomrt_dvhcal(VOI,dose,dose_xmesh,dose_ymesh,dose_zmesh) returns 
% the dvhs for the DVH for all the VOIs in VOI and the dose distribution in the 
% 3D matrix 'dose'.
%
% See also dicomrt_loaddose, roifilt2, roipoly, dicomrt_dvhplot
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check case and set-up some parameters and variables
[dose_temp,type_dose,doselabel,PatientPosition]=dicomrt_checkinput(study);
dose=dicomrt_varfilter(dose_temp);
[VOI_temp]=dicomrt_checkinput(VOI);
VOI=dicomrt_varfilter(VOI_temp);

% Define cell array
DVH=cell(size(VOI,1),2);

% Write VOIs labels
for k=1:size(VOI,1)
    DVH{k,1}=VOI{k,1};
end

% Retrieve dmax
dmax=max(max(max(dose)));

% Build dose grid
dosegrid=zeros(double(int32(dmax)),1);
%for i=1:double(int32(dmax))                    % use with hist 
%    x(i)=dmax/double(int32(dmax))*(0.5+i-1);   % hist uses centers
%end                                            %
for i=1:double(int32(dmax))                     % use with histc
    dosegrid(i)=i*dmax/double(int32(dmax));     % histc uses edges
end                                             %
  
% Calculate voxel volume
[voxelvolume, status]=dicomrt_voxelvolumecal(study,dose_xmesh,dose_ymesh,dose_zmesh);
      
volume_VOI_check=[];
volume_VOI_first=[];

for k=1:length(dvhselect) % loop over VOIs
    % Print header
    disp(['DVH calculation for VOI: ',VOI{dvhselect(k),1}]);
    % Retrieve info necessary to get volume_VOI
    [mask_VOI,volume_VOI,mask4VOI]=dicomrt_mask(VOI_temp,dose_temp,dose_xmesh,dose_ymesh,dose_zmesh,...
        dvhselect(k),'nan','y'); % dose matrix masked in dicomrt_Vlevel
    % Build frequency DVH data
    % case 1: uniform slice thickness
    volume_VOI_first=[volume_VOI_first,volume_VOI];
    if status==0
        vgrid=histc(reshape(mask_VOI{2,1},1,size(mask_VOI{2,1},1)*size(mask_VOI{2,1},2)*size(mask_VOI{2,1},3)),dosegrid);
        % get back voxels with dose<min(dosegrid) cause histc does not
        % account for it
        temp_min=find(mask_VOI{2,1}<dosegrid(1) & mask_VOI{2,1}~=0);
        %temp_min2=find(mask_VOI{2,1}<dosegrid(1));
        if isempty(temp_min)~=1
            vgrid(1)=vgrid(1)+length(temp_min);
        end
        vgrid=vgrid.*voxelvolume(1);
        temp2=cumsum(vgrid);
        volume_VOI_check=[volume_VOI_check,temp2(end)];
    else % case 2: non-uniform slice thickness
        vgrid=zeros(length(dosegrid),1);
        for i=1:size(mask_VOI{2,1},3)
            temp_vgrid=histc(reshape(mask_VOI{2,1}(:,:,i),1,size(mask_VOI{2,1}(:,:,i),1)*size(mask_VOI{2,1}(:,:,i),2)),dosegrid);
            % get back voxels with dose<min(dosegrid) cause histc does not
            % account for it
            temp_min=find(mask_VOI{2,1}(:,:,i)<dosegrid(1) & mask_VOI{2,1}~=0);
            if isempty(temp_min)~=1
                temp_vgrid(1)=temp_vgrid(1)+length(temp_min);
            end
            vgrid=vgrid+temp_vgrid'.*voxelvolume(i);
        end
        temp2=cumsum(vgrid);
        volume_VOI_check=[volume_VOI_check,temp2(end)];
        %for i=1:length(dosegrid)
        %    if i==1
        %        vgrid(i)=dicomrt_Vlevel(mask_VOI,0,dose_xmesh,dose_ymesh,dose_zmesh,...
        %            [[0 dosegrid(i)] 0 0 0],VOI_temp,dvhselect(k),1,volume_VOI);
        %    else
        %        vgrid(i)=dicomrt_Vlevel(mask_VOI,0,dose_xmesh,dose_ymesh,dose_zmesh,...
        %            [[dosegrid(i-1) dosegrid(i)] 0 0 0],VOI_temp,dvhselect(k),1,volume_VOI);
        %    end
        %end
    end
    vgrid=dicomrt_makevertical(vgrid);
    % Store DVH data
    DVH{dvhselect(k),2}{1,1}=mask_VOI;
    DVH{dvhselect(k),2}{2,1}=[dosegrid,vgrid];
    DVH{dvhselect(k),2}{3,1}=volume_VOI;
end
