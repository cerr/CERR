function [PatientPositionCODE] = dicomrt_getPatientPosition(study)
% dicomrt_getPatientPosition(study)
%
% Get Patient Position 
% Return a number (CODE) which correspond to one of the supported cases
% 
% Patient Position codes: 
%
% Head First Supine (HFS) - CODE=1
% Feet First Supine (FFS) - CODE=2 
% Head First Prone  (HFP) - CODE=3
% Feet First Prone  (FFP) - CODE=4
% 
% Example:
%
% [B]=dicomrt_getPatientPosition(A)
%
% if patient position is HFS, dicomrt_getPatientPosition returns "1" in B.
%
% See also: dicomrt_loaddose, dicomrt_ctcreate, dicomrt_createwphantom
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

if iscell(study) == 1 % this is a rtplan warmed for MC export: Patient Position already assigned
    if size(study,2) > 2
        CODE=study{1,2}(9);
    else % this is CT data
        study=study{1,1};
    end
end

if isstruct(study) == 1 
    if strcmpi(study.Modality,'RTPLAN')
        try
            PatientPosition=getfield(study,'PatientSetupSequence','Item_1','PatientPosition');
        catch
            PatientPosition=input('dicomrt_getPatientPosition: Please specify Patient Position: HFS(default),FFS,HFP,FFP: ','s');
            if isempty(PatientPosition)==1
                PatientPosition='HFS';
            end
        end
    elseif strcmpi(study.Modality,'CT')
        PatientPosition=getfield(study,'PatientPosition');
    else
        error('dicomrt_getPatientPosition: could not retrieve PatientPosition field. Exit now')
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