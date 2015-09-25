function [MD,MD_aerr] = dicomrt_MDcal(inputdose,inputerror,dose_xmesh,dose_ymesh,dose_zmesh,VOI,voi2use)
% dicomrt_MDcal(inputdose,inputerror,dose_xmesh,dose_ymesh,dose_zmesh,VOI,voi2use)
%
% Calculate the Mean Dose for a given 3D dose distribution within a given VOI
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
% [A]=dicomrt_MDcal(B,0,dose_xmesh,dose_ymesh,dose_zmesh,demo_voi,9);
% 
% returns in A the mean dose for the dose matrix B and the voi # 9 within demo_voi.
%
% See also dicomrt_MDNcal, dicomrt_MAXcal, dicomrt_MINcal
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check case and set-up some parameters and variables
if inputerror~=0
    [dose_temp,type_dose,doselabel]=dicomrt_checkinput(inputdose,1);
    [derror_temp]=dicomrt_checkinput(inputerror,1);
    dose=dicomrt_varfilter(dose_temp);
    derror=dicomrt_varfilter(derror_temp);
else
    [dose_temp,type_dose,doselabel]=dicomrt_checkinput(inputdose,1);
    dose=dicomrt_varfilter(dose_temp);
    derror=0;
end

% Initialise parameters
count=0;

[mask_dose,volume_VOI,mask4VOI]=dicomrt_mask(VOI,dose_temp,dose_xmesh,dose_ymesh,dose_zmesh,voi2use,'nan','n');
mask_dose_array=mask_dose{2,1};

if size(derror)~=1
    [mask_error,volume_VOI,mask4VOI]=dicomrt_mask(VOI,derror_temp,dose_xmesh,dose_ymesh,dose_zmesh,voi2use,'nan','n');
    mask_error_array=mask_error{2,1};
end

for k=1:size(mask_dose,3)
    [ilocation,jlocation]=find(isnan(mask_dose_array(:,:,k))~=1);
    if isnumeric(ilocation)==1 | isnumeric(jlocation)==1
        for i=1:length(ilocation)
            count=count+1;
            dose_VOI(count)=mask_dose_array(ilocation(i),jlocation(i),k);
            if size(derror)~=1
                % this is absolute error now
                error_VOI(count)=mask_error_array(ilocation(i),jlocation(i),k).*mask_dose_array(ilocation(i),jlocation(i),k);
            else
                error_VOI=0;
            end
        end
    end
end

%if size(derror)~=1 
%    % Mean is calculated as weighted average of data points
%    MD=sum(dose_VOI(:)./error_VOI(:).^2)./sum(1./error_VOI(:).^2);
%    % error is calulated as standard error of the mean
%    MD_aerr=std(dose_VOI)./sqrt(length(MD));
%else
%    % Mean is calculated as average of data points
%    MD=mean(dose_VOI);
%    % error is calulated as standard error of the mean
%    MD_aerr=std(dose_VOI)./sqrt(length(MD));
%end

MD=mean(dose_VOI);
MD_aerr=0;
