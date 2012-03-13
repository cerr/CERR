function [CT2dm] = dicomrt_fitCT2dm(ct_matrix,ct_xmesh,ct_ymesh,ct_zmesh,rtdose_xmesh,rtdose_ymesh,rtdose_zmesh)
% dicomrt_fitCT2dm(ct_matrix,ct_xmesh,ct_ymesh,ct_zmesh,rtdose_xmesh,rtdose_ymesh,rtdose_zmesh)
%
% Fit CT data to 3D dose matrix.
%
% ct_matrix is the CT dataset
% ct_xmesh,ct_ymesh,ct_zmesh are the coordinates of the center of the ct-pixel
% rtdose_xmesh,rtdose_ymesh,rtdose_zmesh coordinates of the center of the dose-pixel
%
% See also dicomrt_loaddose, dicomrt_loadct, dicomrt_fitdm2CT
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check case and set-up some parameters and variables
[ct_matrix_temp,type,label,PatientPosition]=dicomrt_checkinput(ct_matrix);
ct_matrix=dicomrt_varfilter(ct_matrix_temp);

% check number of available CT slices
if size(rtdose_zmesh,3) > size(ct_zmesh,1);
   error('dicomrt_fitCT2dm: not enough number of CT slices. Exit now !')
end

% build 2d grids used for interpolation
rtdose_xmesh=rtdose_xmesh';
ct_xmesh=ct_xmesh';

[ct_xmesh_2d,ct_ymesh_2d]=dicomrt_build2dgrid(ct_xmesh,ct_ymesh);
[dose_xmesh_2d,dose_ymesh_2d]=dicomrt_build2dgrid(rtdose_xmesh,rtdose_ymesh);

% 1a) resize ct_matrix using dose_xmesh, dose_ymesh, dose_zmesh
% loop over dose_zmesh size since the rt plan could have been performed on a subset of the original ct images
for i=1:length(rtdose_zmesh)
    if i==1 % locate z position of the first slice to start with
      first_zlocation=rtdose_zmesh(i);
      for k=1:length(ct_zmesh)
         temp=num2str(ct_zmesh(k));
         array=char(temp,num2str(first_zlocation));
         if array(1,:)==array(2,:);
            break
         end
      end
      zstart=k; % match with dose matrix
   end
   CT2dm(:,:,i)=interp2(ct_xmesh_2d,ct_ymesh_2d,ct_matrix(:,:,k+i-1), ...
       dose_xmesh_2d,dose_ymesh_2d,'nearest');
end

% Restore original variable format
[CT2dm]=dicomrt_restorevarformat(ct_matrix_temp,CT2dm);
