function [matrix_mask,volume_VOI,mask,voxelvolume,area] = dicomrt_mask(voi,inpmatrix,ct_xmesh,ct_ymesh,ct_zmesh,selected_voi,filter,mask_open)
% dicomrt_mask(voi,inpmatrix,ct_xmesh,ct_ymesh,ct_zmesh,selected_voi,filter,mask_open)
%
% Mask 3D matrix using anatomical structures.
%
% voi is a cell array and contains the Volumes of Interest
% inpmatrix contains the matrix that will be masked
% ct_xmesh, ct_ymesh, ct_zmesh are x-y-z coordinates of the center of the matrix voxels
% selected_voi is the VOI used to mask the ct matrix
% filter is an OPTIONAL parameter which specify the type of filter used for the mask. 
%    Filter defaults to 0, hence if not given every pixel outside selected_voi will be "0". 
%    Valid filters are 'NaN' or 'Inf'.
% mask_open is an OPTIONAL parameter which control if the masked matrix
%    will have the same dimensions of the original matrix (mask_open='y') or if it will have the 
%    same dimension of the contour (mask_open='n')
%
% Example:
%
% [A,vol,B]=dicomrt_maskct(VOI,C,ct_xmesh,ct_ymesh,ct_zmesh) returns in A
% the matrix C masked using the first VOI outline in "VOI" (usually this
% correspond to the patient outline). 
% The volume of the masked volume is stored in vol.
% The matrix used to perform the mask is stored in B.
%
% See also dicomrt_ctcreate, dicomrt_loaddose, dicomrt_mask
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check number of argument and set-up some parameters and variables
error(nargchk(6,8,nargin))

if exist('mask_open')~=1
    mask_open='y';
end

% Initialize filter
if exist('filter')==1
    if isnumeric(filter)==1
        filter=num2str(filter);
    end
else
    filter=0;
end

% Check case and set-up some parameters and variables
[matrix_temp,type,label,PatientPosition]=dicomrt_checkinput(inpmatrix);
matrix=dicomrt_varfilter(matrix_temp);
[voi_temp]=dicomrt_checkinput(voi);
voi=dicomrt_varfilter(voi_temp);
voitype=dicomrt_checkvoitype(voi_temp);

% downgrading 3D to 2D for backward compatibility
if isequal(voitype,'3D')==1
    voi=dicomrt_3dto2dVOI(voi);
end

% initialize variables for consistent volume calculation
% based on masked image
area_VOI=0;
volume_VOI=0;

% Calculate voxel volume
[voxelvolume, status]=dicomrt_voxelvolumecal(inpmatrix,ct_xmesh,ct_ymesh,ct_zmesh);

% Initialize filter
mask=ones(size(matrix));
matrix_mask=zeros(size(matrix));
matrix_mask(:)=eval(filter);

% Mask the matrix using the selected VOI
voiZ=dicomrt_makevertical(dicomrt_getvoiz(voi_temp,selected_voi));

% Progress bar
h = waitbar(0,['Masking progress:']);
set(h,'Name','dicomrt_mask: masking objects');

locate_slice=zeros(length(ct_zmesh),1);
locate_slice(:)=nan;
locate_slice=dicomrt_makevertical(locate_slice);

for j=1:size(matrix,3)
    temp=dicomrt_findsliceVECT(ct_zmesh,j,voiZ,PatientPosition);
    if isempty(temp)~=1
        locate_slice(j)=temp;
        %BW=roipoly(ct_xmesh,ct_ymesh,matrix(:,:,j),voi{selected_voi,2}{j}(:,1)',voi{selected_voi,2}{j}(:,2));
        BW=roipoly(ct_xmesh,ct_ymesh,matrix(:,:,j),voi{selected_voi,2}{locate_slice(j)}(:,1)',voi{selected_voi,2}{locate_slice(j)}(:,2));
        ONE=ones(size(BW,1),size(BW,2));
        BWinv=xor(ONE,BW);
        %area_VOI=size(find(BWinv==0),1);
        %volume_VOI=volume_VOI+area_VOI.*voxelvolume(locate_slice(j));
        matrix_mask(:,:,j)=roifilt2(eval(filter),matrix(:,:,j),BWinv);
        %matrix_mask(:,:,locate_slice(j))=roifilt2(eval(filter),matrix(:,:,locate_slice(j)),BWinv);
        %area_VOI=length(find(isnan(matrix_mask(:,:,locate_slice(j)))~=1));
        %
        % The condition that matrix_mask elements must be different from
        % zero arise from the Matlab masking process and from the
        % calculation matrix actually used by the TPS. We cannot be sure
        % that the masked matrix correspond exactly to the calculation
        % matrix used by the TPS. Hence values set to "zero" in the calculation 
        % matrix could be because they are relly outside the calculation
        % matrix or because they are voxels "outside" the calculation
        % matrix which were acquired as part of the masked matrix during the masking process.
        % This effect is more important for structures close to region
        % where there is no beam, such as the patient outline. 
        % 
        area_VOI=size(find(isnan(matrix_mask(:,:,j))~=1 & matrix_mask(:,:,j)~=0),1);
        area(j)=area_VOI.*voxelvolume(j);
        volume_VOI=volume_VOI+area_VOI.*voxelvolume(j);
        mask(:,:,j)=BWinv;
    else
        area(j)=0;
    end
    waitbar(j/size(matrix,3),h);
end

if mask_open =='N' | mask_open =='n'
    [dummy,locate_slice_min]=min(locate_slice);
    [dummy,locate_slice_max]=max(locate_slice);
    matrix_mask_new=matrix_mask(:,:,locate_slice_min:locate_slice_max);
    mask_new=mask(:,:,locate_slice_min:locate_slice_max);
    % Restore original variable format
    [matrix_mask]=dicomrt_restorevarformat(matrix_temp,matrix_mask_new);
else
    % Restore original variable format
    [matrix_mask]=dicomrt_restorevarformat(matrix_temp,matrix_mask);
end

% Close progress bar
close(h);
