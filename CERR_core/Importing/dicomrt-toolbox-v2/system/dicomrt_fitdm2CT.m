function [dm2CT] = dicomrt_fitdm2CT(cell_case_study,ct_matrix,ct_xmesh,ct_ymesh,ct_zmesh,rtdose_xmesh,rtdose_ymesh,rtdose_zmesh,VOI,voi2use)
% dicomrt_fitdm2CT(cell_case_study,ct_matrix,ct_xmesh,ct_ymesh,ct_zmesh,rtdose_xmesh,rtdose_ymesh,rtdose_zmesh,,voi2use)
%
% Fit CT data to 3D dose matrix.
%
% cell_case_study is the rtplan dataset
% ct_matrix is the CT dataset
% ct_xmesh,ct_ymesh,ct_zmesh are the coordinates of the center of the ct-pixel
% rtdose_xmesh,rtdose_ymesh,rtdose_zmesh coordinates of the center of the dose-pixel
% VOI is a cell array which contain the volumes of interest (OPTIONAL). 
% voi2use is an OPTIONAL vector pointing to the number of VOIs to be displayed 
%         voi2use defaults to 1 if not given or if set to 0
%
% See also dicomrt_loaddose, dicomrt_loadct, dicomrt_fitCT2dm
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check number of argument
error(nargchk(8,10,nargin))

% check number of available CT slices
if size(rtdose_zmesh,3) > size(ct_zmesh,1);
   error('dicomrt_fitdm2CT: not enough number of CT slices. Exit now !')
end

voiref=1;

% Check case and set-up some parameters and variables
[dose_temp,type_dose,label,PatientPosition]=dicomrt_checkinput(cell_case_study);
dose=dicomrt_varfilter(dose_temp);

% mask dose matrix with VOI
if exist('VOI')==1 & exist('voi2use')==1
    dose=dicomrt_mask(VOI,dose,rtdose_xmesh,rtdose_ymesh,rtdose_zmesh,voiref);
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
   %dm2CT(:,:,i)=interp2(ct_xmesh_2d,ct_ymesh_2d,ct_matrix(:,:,k+i-1), ...
   %    dose_xmesh_2d,dose_ymesh_2d,'nearest');
   dm2CT(:,:,i)=interp2(dose_xmesh_2d,dose_ymesh_2d,dose(:,:,k+i-1),ct_xmesh_2d,ct_ymesh_2d,'nearest');
end

dm2CT(find(isnan(dm2CT)==1))=0.;

% Restore original variable format
[dm2CT]=dicomrt_restorevarformat(ct_matrix,dm2CT);
