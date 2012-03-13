function [dose_ratio] = dicomrt_doseratio(doseone,dosetwo)
% dicomrt_doseratio(doseone,dosetwo)
%
% Calculate dose ratio between two 3D matrices
%
% doseone and dosetwo can be rtplan and/or monte carlo 3D dose distributions.
%
% NOTE:
% Warnings for divisions by zero are switched off during the call to this function.
% Infinite values are set to nan (not-a-number).
%
% Example:
%
% [doseratio]=dicomrt_doseratio(doseone,dosetwo)
%
% returns in doseratio the ratio: dosetwo/doseone. 
%
% See also: dicomrt_dosediff
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check case and set-up some parameters and variables
[doseone_dose_temp,type_doseone_dose,labeld1,PatientPosition]=dicomrt_checkinput(doseone);
[dosetwo_dose_temp,type_dosetwo_dose,labeld1,PatientPosition]=dicomrt_checkinput(dosetwo);

doseone_dose=dicomrt_varfilter(doseone_dose_temp);
dosetwo_dose=dicomrt_varfilter(dosetwo_dose_temp);

% Perform ratio: swith off and back on warnings
warning off MATLAB:divideByZero;
dose_ratio=dosetwo_dose./doseone_dose;
warning on MATLAB:divideByZero;

% Discard infinite values
dose_ratio(find(isinf(dose_ratio)==1))=nan;

% Restore original variable format
[dose_ratio]=dicomrt_restorevarformat(dosetwo,dose_ratio);

% Label Plan and update time of creation
if iscell(dose_ratio)==1
    dose_ratio{1,1}{1}.RTPlanLabel=[dose_ratio{1,1}{1}.RTPlanLabel,'-DRATIO'];
    dose_ratio{1,1}{1}.RTPlanDate=date;
    time=fix(clock);
    creationtime=[num2str(time(4)),':',num2str(time(5))];
    dose_ratio{1,1}{1}.RTPlanTime=creationtime;
end