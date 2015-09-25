function [moutput,type,label,PatientPositionCODE]=dicomrt_checkinput(minput,force)
% dicomrt_checkinput(minput,force)
%
% Check the validity of the input variable.
% Returns the input variable, type, label and patient orientation.
%
% minput is the input dataset
% force is a parameter which force, if existing and different from 0, the function to check 
%    for PatientPosition.
%
% See also: dicomrt_loaddose, dicomrt_loadct, dicomrt_loadmcdose
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check number of argument
error(nargchk(1,2,nargin))

if nargin==1
    force=0;
end

if iscell(minput) == 1 & size(minput,1) == 3 % OK accepted input
    try 
        header=minput{1,1}{1};
    catch
        header=minput{1,1};
    end
    modality=header.Modality;
    if isequal(modality,'CT') % CT data
        type='ct';
        label='CT units [Houns]';
        PatientPositionCODE=dicomrt_getPatientPosition(header);
        moutput=minput;
    elseif isequal(modality,'RTSTRUCT') % VOI data
        type='voi';
        label='VOI';
        PatientPositionCODE=-1; % N/A
        moutput=minput;
    elseif isequal(modality,'RTPLAN') % TPS or MC dose
        RTPLabel=header.RTPlanLabel;
        if strfind(RTPLabel,'-MCDOSE'); 
            % this is a MC DOSE
            if iscell(minput{2,1}) == 1 % this is a MC dose and contains segments contribution
                disp('Input variable is a MC dose containing segments contribution. Adding segment''s dose');
                totaldose=dicomrt_addmcdose(minput{2,1}); %add segments' contribution in a 3D minput
                moutput=minput;
                moutput{2,1}=totaldose;
            else
                moutput=minput;
            end
            type='mc';
            label='MC dose map [Gy]';
            PatientPositionCODE=dicomrt_getPatientPosition(header);
        elseif strfind(RTPLabel,'-DDIFF'); 
            % this is a dose difference
            moutput=minput;
            type='ddiff';
            label='Dose difference';
            PatientPositionCODE=dicomrt_getPatientPosition(header);
        elseif strfind(RTPLabel,'-DRATIO'); 
            % this is a dose ratio
            moutput=minput;
            type='dratio';
            label='Dose ratio';
            PatientPositionCODE=dicomrt_getPatientPosition(header);
        else
            % this is a TPS DOSE
            moutput=minput;
            type='RTPLAN';
            label='RTPLAN dose map [Gy]';
            PatientPositionCODE=dicomrt_getPatientPosition(header);
        end
    end
elseif isnumeric(minput)==1 % this is a simple 3D matrix
    moutput=minput;
    type='other';
    label=[inputname(1),' matrix'];
    if force==0
        warning('dicomrt_checkinput: The input variable is a 3D matrix. Unable to determine Patient Position.');
        PatientPosition=input('dicomrt_checkinput: Please specify Patient Position: HFS(default),FFS,HFP,FFP: ','s');
        if isempty(PatientPosition)==1
            PatientPosition='HFS';
        end
        
        if strcmpi(PatientPosition, 'HFS')
            PatientPositionCODE = 1;
        elseif strcmpi(PatientPosition, 'FFS')
            PatientPositionCODE = 2;
        elseif strcmpi(PatientPosition, 'HFP')
            PatientPositionCODE = 3;
        elseif strcmpi(PatientPosition, 'FFP')
            PatientPositionCODE = 4;
        end

    end
else
    error('dicomrt_checkinput: Input matrix does not have a supported format. Exit now !');
end