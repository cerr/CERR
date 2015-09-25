function [MDN,MDN_aerr] = dicomrt_MDNcal(inputdose,inputerror,dose_xmesh,dose_ymesh,dose_zmesh,VOI,voi2use)
% dicomrt_MDNcal(inputdose,inputerror,dose_xmesh,dose_ymesh,dose_zmesh,VOI,voi2use)
%
% Calculate the median dose for a given 3D dose distribution within a given VOI
% 
% inputdose is the input 3D dose (e.g. RTPLAN or MC generated)
% inputerror is the relative error asociated with the calculated dose. If inputerror=0 error
% calculation is not performed (e.g. for TPS dose matrices), otherwise
% inputerror dimensions must match those of inputdose (e.g. for MC dose matrices).
% dose_xmesh,dose_ymesh,dose_zmesh are x-y-z coordinates of the center of the dose-pixel 
% 
% VOI is a cell array which contain the patients VOIs as read by dicomrt_loadvoi
% voi2use is a vector pointing to the number of VOIs to be used ot the analysis and for the display.
% NOTE: voi2use cannot be a vector. VOIs can be added to the plot later holding it on and using dicomrt_rendervoi.
% NOTE:isocontour on each sclice must be a closed single line!!!!! 
%
% Example:
%
% [A]=dicomrt_MDNcal(B,dose_xmesh,dose_ymesh,dose_zmesh,demo_voi,9);
% 
% returns in A the median dose for the dose matrix B and the voi # 9 within demo_voi.
%
% See also dicomrt_MDcal, dicomrt_MAXcal, dicomrt_MINcal
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check case and set-up some parameters and variables
[dose_temp,derror_temp,type_dose,doselabel]=dicomrt_checkinputanderr(inputdose,inputerror,1);
dose=dicomrt_varfilter(dose_temp);
derror=dicomrt_varfilter(derror_temp);

% Initialise parameters
count=0;

[mask_dose,volume_VOI,mask4VOI]=dicomrt_mask(VOI,dose_temp,dose_xmesh,dose_ymesh,dose_zmesh,voi2use,'nan','n');

if size(derror)~=1
    [mask_error,volume_VOI,mask4VOI]=dicomrt_mask(VOI,derror_temp,dose_xmesh,dose_ymesh,dose_zmesh,voi2use,'nan','n');
end

for k=1:size(mask_dose,3)
    [ilocation,jlocation]=find(isnan(mask_dose{2,1}(:,:,k))~=1);
    if isnumeric(ilocation)==1 | isnumeric(jlocation)==1
        for i=1:length(ilocation)
            count=count+1;
            dose_VOI(count)=mask_dose{2,1}(ilocation(i),jlocation(i),k);
            if size(derror)~=1
                % this is absolute error now
                error_VOI(count)=mask_error{2,1}(ilocation(i),jlocation(i),k)*mask_dose{2,1}(ilocation(i),jlocation(i),k);
            else
                error_VOI=0;
            end
        end
    end
end

MDN=median(dose_VOI);
MDN_aerr=0;
