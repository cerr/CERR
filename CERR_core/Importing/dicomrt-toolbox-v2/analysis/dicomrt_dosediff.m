function [diff_dose] = dicomrt_dosediff(doseone,dosetwo,method,dose_xmesh,dose_ymesh,dose_zmesh,VOI,voi2use)
% dicomrt_dosediff(doseone,dosetwo,method,dose_xmesh,dose_ymesh,dose_zmesh,VOI,voi2use)
%
% Calculate dose difference between two 3D matrices
% 
% doseone and dosetwo can be rtplan and/or monte carlo 3D dose distributions.
% method is an OPTIONAL rameter which specify the way doses are normalised
%
% 1. method=a          matrices are normalised to the value a expressed in Gy
% 2. method=[x, y, z]  matrices are independently normalised to the dose value at point (x,y,z) (in cm)
% 3. method=dmean      matrices are independently normalised to the mean dose value in VOI voi2use (key insensitive)
% 4. method=0          matrices are not normalised (default)   
%
% dose_xmesh,dose_ymesh,dose_zmesh are OPTIONAL x-y-z coordinates of the center of the matrix voxels
% VOI is a cell array which contain the patients VOIs (OPTIONAL to use with option 3)
% voi2use is a vector pointing to the number of VOI (OPTIONAL to use with option 3)
%
% Examples:
%
% C=dicomrt_dosediff(A,B,0,dose_xmesh,dose_ymesh,dose_zmesh,VOI,0)
% Store in C the dose difference between B and A. C=(B-A). 
%
% C=dicomrt_dosediff(A,B,60,method,dose_xmesh,dose_ymesh,dose_zmesh,VOI,voi2use)
% Store in C the dose difference between Bnorm and Anorm. C=(Bnorm-Anorm), where
% Bnorm and Anorm are normalised to 60Gy (100%).
%
% C=dicomrt_dosediff(A,B,[10.5 -18 7],method,dose_xmesh,dose_ymesh,dose_zmesh)
% Store in C the dose difference between Bnorm and Anorm. C=(Bnorm-Anorm), where
% Bnorm and Anorm are normalised to the respective dose values at dnorm=(10.5 -18 7).
%
% C=dicomrt_dosediff(A,B,'Dmean',method,dose_xmesh,dose_ymesh,dose_zmesh,VOI,3)
% Store in C the dose difference between Bnorm and Anorm. C=(Bnorm-Anorm), where
% Bnorm and Anorm are normalised to the respective mean dose values in VOI number 3
%
% See also: dicomrt_doseratio, dicomrt_loadmcdose
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check number of argument and set-up some parameters and variables
error(nargchk(2,8,nargin))

% Define parameter
voilookup=1;
filter=0;
dosenorm=0;

% Check case and set-up some parameters and variables
[doseone_dose_temp,type_doseone_dose,labeld1]=dicomrt_checkinput(doseone,1);
[dosetwo_dose_temp,type_dosetwo_dose,labeld1]=dicomrt_checkinput(dosetwo,1);
doseone_dose=dicomrt_varfilter(doseone_dose_temp);
dosetwo_dose=dicomrt_varfilter(dosetwo_dose_temp);

if exist('VOI')==1 & exist('voi2use')==1
    if strcmpi(type_doseone_dose,'mc')==1
        doseone_dose_temp=dicomrt_mask(VOI,doseone_dose_temp,dose_xmesh,dose_ymesh,dose_zmesh,voilookup,filter,'y');
    end
    if strcmpi(type_dosetwo_dose,'mc')==1
        dosetwo_dose_temp=dicomrt_mask(VOI,dosetwo_dose_temp,dose_xmesh,dose_ymesh,dose_zmesh,voilookup,filter,'y');
    end
end

% Create label for dose diff
%if type_doseone_dose=='mc' & type_dosetwo_dose=='rtplan'
%    dose_diff_label='rtplan -mc'
%elseif type_doseone_dose=='mc' & type_dosetwo_dose=='mc'
%    dose_diff_label='mc2 - mc1'
%elseif type_doseone_dose=='rtplan' & type_dosetwo_dose=='mc'
%    dose_diff_label='mc - rtplan'
%else
%    dose_diff_label='rtplan2 - rtplan1'
%end

if exist('method')==1
    if isnumeric(method)==1 & length(method)==1 & method~=0
        % normalize to a specific dose level passed through "method"
        doseone_dose=doseone_dose./method.*100;
        dosetwo_dose=dosetwo_dose./method.*100;
        diff_dose=dosetwo_dose-doseone_dose;
    elseif isnumeric(method)==1 & length(method)==1 & method==0
        % no normalisation is carried out
        diff_dose=dosetwo_dose-doseone_dose;
    elseif isnumeric(method)==1 & length(method)==3 & ...
            (exist('dose_xmesh')~=1 | exist('dose_ymesh')~=1 | exist('dose_zmesh')~=1)
        error('dicomrt_dosediff: This normalisation method requires mesh to be provided. Exit now!');
    elseif isnumeric(method)==1 & length(method)==3 & ...
            (exist('dose_xmesh')==1 | exist('dose_ymesh')==1 | exist('dose_zmesh')==1)
        % normalize to a specific point in 3D passed through "method"
        locx=dicomrt_findpointVECT(dose_xmesh,method(1));
        locy=dicomrt_findpointVECT(dose_ymesh,method(2));
        locz=dicomrt_findpointVECT(dose_zmesh,method(3));
        doseone_dose=doseone_dose./doseone_dose(locy,locx,locz).*100;
        dosetwo_dose=dosetwo_dose./dosetwo_dose(locy,locx,locz).*100;
        diff_dose=dosetwo_dose-doseone_dose;
    elseif ischar(method)==1 & strcmpi(method,'dmean')==1 & ...
            (exist('VOI')~=1 | exist('voi2use')~=1)
        error('dicomrt_dosediff: This normalisation method requires VOI and voi2use to be provided. Exit now!');
    elseif ischar(method)==1 & strcmpi(method,'dmean')==1 & ...
            (exist('VOI')==1 | exist('voi2use')==1)
        % normalize to dmean
        dmean_one=dicomrt_MDcal(doseone,0,dose_xmesh,dose_ymesh,dose_zmesh,VOI,voi2use);
        dmean_two=dicomrt_MDcal(dosetwo,0,dose_xmesh,dose_ymesh,dose_zmesh,VOI,voi2use);
        doseone_dose=doseone_dose./dmean_one.*100;
        dosetwo_dose=dosetwo_dose./dmean_two.*100;
        diff_dose=dosetwo_dose-doseone_dose;
    end
else
    % no normalisation is carried out
    diff_dose=dosetwo_dose-doseone_dose;
end

% Restore original variable format
[diff_dose]=dicomrt_restorevarformat(dosetwo_dose_temp,diff_dose);

% Label Plan and update time of creation
if iscell(diff_dose)==1
    diff_dose{1,1}{1}.RTPlanLabel=[diff_dose{1,1}{1}.RTPlanLabel,'-DDIFF'];
    diff_dose{1,1}{1}.RTPlanDate=date;
    time=fix(clock);
    creationtime=[num2str(time(4)),':',num2str(time(5))];
    diff_dose{1,1}{1}.RTPlanTime=creationtime;
end
