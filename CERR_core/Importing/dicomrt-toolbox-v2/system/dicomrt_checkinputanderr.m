function [moutput,eoutput,type,label,PatientPositionCODE]=dicomrt_checkinputanderr(minput,einput,force)
% dicomrt_checkinput(minput,einput,force)
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
error(nargchk(2,3,nargin))

if nargin==2
    force=0;
end

if iscell(minput) == 1 & size(minput,1) == 3 % OK accepted input
    try 
        header=minput{1,1}{1};
    catch
        header=minput{1,1};
    end
    modality=header.Modality;
    if strcmpi(modality,'CT') % CT data
        type='ct';
        label='CT units [Houns]';
        PatientPositionCODE=dicomrt_getPatientPosition(header);
        moutput=minput;
        eoutput=0; % default
        if isequal(einput,0)~=1 & size(einput)==size(moutput)
            eoutput=einput;
        elseif isequal(einput,0)~=1 & size(einput)~=size(moutput)
            error('dicomrt_checkinputanderr: Dose and error matrix have inconsistent dimensions. Exit now!');
        end
    elseif strcmpi(modality,'RTSTRUCT') % VOI data
        type='voi';
        label='VOI';
        PatientPositionCODE=-1; % N/A
        moutput=minput;
        eoutput=0; % default
    elseif strcmpi(modality,'RTPLAN') % TPS or MC dose
        RTPLabel=header.RTPlanLabel;
        if strfind(RTPLabel,'-MCDOSE'); 
            % this is a MC DOSE
            if iscell(minput{2,1}) == 1 % this is a MC dose and contains segments contribution
                %disp('Input variable is a MC dose containing segments contribution. Adding segment''s dose');
                if iscell(einput)~=1 
                    if einput==0
                        %warning('dicomrt_checkinputanderr: MC dose was input but error calculation was not requested');
                        eoutput=0;
                    end
                elseif iscell(einput) == 1 & size(einput{2,1},1) == size(minput{2,1},1) 
                    % this is a MC error compatible with MC dose
                    [totaldose,totalerror]=dicomrt_addmcdose(minput{2,1},einput{2,1}); % add segments' contribution in a 3D matrix
                    moutput=minput;
                    moutput{2,1}=totaldose;
                    eoutput=einput;
                    eoutput{2,1}=totalerror;
                    type='mc';
                    label='MC dose map [Gy]';
                else
                    error('dicomrt_checkinputanderr: Dose and error matrix have inconsistent dimensions. Exit now!');
                end
            else
                %disp('Input variable is a MC dose');
                %moutput=minput{2,1};
                moutput=minput;
                type='mc';
                label='MC dose map [Gy]';
                if iscell(einput)~=1 
                    if einput==0
                        %warning('dicomrt_checkinputanderr: MC dose was input but error calculation was not requested');
                        eoutput=0;
                    end
                elseif iscell(einput) == 1 & size(einput{2,1},1) == size(minput{2,1},1)
                    eoutput=einput;
                else
                    error('dicomrt_checkinputanderr: Dose and error matrix have inconsistent dimensions. Exit now!');
                end
            end
            PatientPositionCODE=dicomrt_getPatientPosition(header);
        else
            % this is a TPS DOSE
            moutput=minput;
            type='rtplan';
            label='Rtplan dose map [Gy]';
            PatientPositionCODE=dicomrt_getPatientPosition(header);
            eoutput=0; % default: assume TPS does not have error
            if isequal(einput,0)~=1 & size(einput)==size(moutput)
                eoutput=einput;
            elseif isequal(einput,0)~=1 & size(einput)~=size(moutput)
                error('dicomrt_checkinputanderr: Dose and error matrix have inconsistent dimensions. Exit now!');
            end
        end
    end
elseif isnumeric(minput)==1 % this is a simple 3D matrix
    moutput=minput;
    type='other';
    label=[inputname(1),' matrix'];
        eoutput=0; % default
    if isequal(einput,0)~=1 & size(einput)==size(moutput)
        eoutput=einput;
    elseif isequal(einput,0)~=1 & size(einput)~=size(moutput)
        error('dicomrt_checkinputanderr: Dose and error matrix have inconsistent dimensions. Exit now!');
    end
    if force==0
        warning('dicomrt_checkinputanderr: The input variable is a 3D matrix. Unable to determine Patient Position.');
        PatientPosition=input('dicomrt_checkinputanderror: Please specify Patient Position: HFS(default),FFS,HFP,FFP: ','s');
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
    error('dicomrt_checkinputanderr: Input matrix does not have a supported format. Exit now !');
end