function [DMAX,DMAX_aerr] = dicomrt_MAXcal(inputdose,inputerror,dose_xmesh,dose_ymesh,dose_zmesh,VOI,voi2use)
% dicomrt_MAXcal(inputdose,inputerror,dose_xmesh,dose_ymesh,dose_zmesh,VOI,voi2use)
%
% Calculate the MAX Dose for a given 3D dose distribution within a given VOI
% 
% inputdose is the input 3D dose (e.g. RTPLAN or MC generated)
% inputerror is the relative error asociated with the calculated dose. If inputerror=0 error
% calculation is not performed (e.g. for TPS dose matrices), otherwise
% inputerror dimensions must match those of inputdose (e.g. for MC dose matrices).
% dose_xmesh,dose_ymesh,dose_zmesh are x-y-z coordinates of the center of the dose-pixel 
% 
% VOI is a cell array which contain the patients VOIs as read by dicomrt_loadvoi
% voi2use is a vector pointing to the number of VOIs to be used ot the analysis and for the display.
%
% Example:
%
% [A]=dicomrt_MAXcal(B,0,dose_xmesh,dose_ymesh,dose_zmesh,demo_voi,9);
% 
% returns in A the max dose for the dose matrix B and the voi # 9 within demo_voi.
%
% See also dicomrt_MDNcal, dicomrt_MDcal, dicomrt_MINcal
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check case and set-up some parameters and variables
[dose_temp,derror_temp,type_dose,doselabel]=dicomrt_checkinputanderr(inputdose,inputerror,1);
dose=dicomrt_varfilter(dose_temp);
derror=dicomrt_varfilter(derror_temp);
[VOI_temp,type,label]=dicomrt_checkinput(VOI);
VOI=dicomrt_varfilter(VOI_temp);

% Initialise parameters
count=0;

[mask_dose,volume_VOI,mask4VOI]=dicomrt_mask(VOI_temp,dose_temp,dose_xmesh,dose_ymesh,dose_zmesh,voi2use,'nan','n');
mask=dicomrt_varfilter(mask_dose);

if size(derror)~=1
    [mask_error,volume_VOI,mask4VOI]=dicomrt_mask(VOI_temp,derror_temp,dose_xmesh,dose_ymesh,dose_zmesh,voi2use,'nan','n');
    msk_error=dicomrt_varfilter(mask_error);
end

for k=1:size(mask,3)
    [ilocation,jlocation]=find(isnan(mask(:,:,k))~=1);
    if isnumeric(ilocation)==1 | isnumeric(jlocation)==1
        for i=1:length(ilocation)
            count=count+1;
            dose_VOI(count)=mask(ilocation(i),jlocation(i),k);
            if size(derror)~=1
                % this is absolute error now
                error_VOI(count)=msk_error(ilocation(i),jlocation(i),k).*mask(ilocation(i),jlocation(i),k);
            else
                error_VOI=0;
            end
        end
    end
end

if size(derror)~=1 
    % Mean is calculated as weighted average of data points
    [DMAX,I]=max(dose_VOI);
    % error is calulated as standard error of the mean
    DMAX_aerr=error_VOI(I);
else
    % Mean is calculated as average of data points
    DMAX=max(dose_VOI);
    % error is calulated as standard error of the mean
    DMAX_aerr=0;
end
