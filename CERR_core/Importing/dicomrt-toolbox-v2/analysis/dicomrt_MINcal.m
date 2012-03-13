function [DMIN,DMIN_aerr] = dicomrt_MINcal(inputdose,inputerror,dose_xmesh,dose_ymesh,dose_zmesh,VOI,voi2use)
% dicomrt_MINcal(inputdose,inputerror,dose_xmesh,dose_ymesh,dose_zmesh,VOI,voi2use)
%
% Calculate the MIN Dose for a given 3D dose distribution within a given VOI
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
% [A]=dicomrt_MINcal(B,0,dose_xmesh,dose_ymesh,dose_zmesh,demo_voi,9);
% 
% returns in A the min dose for the dose matrix B and the voi # 9 within demo_voi.
%
% NOTE: 
% due to the algorithm that MATLAB uses to filter matrices (roipoly), it can happen that 
% some of the voxels which are partially outside the patient are included in the VOI.
% This can happen when the border of the VOI are too close to the patient outline with 
% respect to the size of the calculation matrix used.
% This is not a problem for MC which calculate dose also outside the patient outline.
% It may represent a problem when dealing with TPS generated data, which do not calculate
% dose outside the patient outline, because voxels with zero dose can be counted in the target
% volume. This event is rare (1/10000) and should not influence dose analysis.
% A simple way to overcome this problem is to define VOIs as separate as possible.
% In this function the minimum dose ~=0 is reported.
%
% See also dicomrt_MDNcal, dicomrt_MDcal, dicomrt_MAXcal
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
    [DMIN,I]=min(dose_VOI);
    % Dose min cannot be 0.
    if DMIN==0
        dose_VOI(I)=[];
        [DMIN,I]=min(dose_VOI);
    end
    % error is calulated as standard error of the mean
    DMIN_aerr=error_VOI(I);
else
    % Mean is calculated as average of data points
    [DMIN,I]=min(dose_VOI);
    % Dose min cannot be 0.
    if DMIN==0
        dose_VOI(I)=[];
        [DMIN,I]=min(dose_VOI);
    end
    % error is calulated as standard error of the mean
    DMIN_aerr=0;
end
