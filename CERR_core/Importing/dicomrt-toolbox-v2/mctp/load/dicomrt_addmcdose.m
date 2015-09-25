function [totalMCdose,totalMCerror] = dicomrt_addmcdose(MCdose,MCerror)
% dicomrt_addmcdose(MCdose,MCerror)
%
% Add segment's contribution of Monte Carlo 3D dose distribution calculated for rtplanformc 
% 
% MCdose and MCerror are two cell arrays with the following structure
%
%   beam name     3d matrix/segment
%  --------------------------------------
%  | [beam 1] | [1st segment 3dmatrix ] |
%  |          | [1st segment 3dmatrix ] |
%  |          |                         |
%  |          | [nth segment 3dmatrix ] |
%  --------------------------------------
%  |   ...               ...            |
%  --------------------------------------
%  | [beam 2] | [1st segment 3dmatrix ] |
%  |          | [1st segment 3dmatrix ] |
%  |          |                         |
%  |          | [nth segment 3dmatrix ] |
%  --------------------------------------
%
% Example:
%
% [totalMCdose,totalMCerror]=dicomrt_addmcdose(A,B)
%
% add all the 3D MC dose and errors from segments, stored respectively in A and B,  
% and return them in totalMCdose and totalMCerror
%
% See also dicomrt_read3ddose, dicomrt_loaddose, dicomrt_loadmcdose
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check number of argument
error(nargchk(1,2,nargin))

% Check case and set-up some parameters and variables
if nargin==1
    [study_temp,type_dose,label]=dicomrt_checkinput(MCdose,1);
    MCdose=dicomrt_varfilter(study_temp);
else
    [study_temp,type_dose,label]=dicomrt_checkinput(MCdose,1);
    [studye_temp,type_dose,label]=dicomrt_checkinput(MCerror,1);
    MCdose=dicomrt_varfilter(study_temp);
    MCerror=dicomrt_varfilter(studye_temp);    
end

% Check case
if nargin==2 & (iscell(MCdose)~=1 | iscell(MCerror)~=1)
    error('dicomrt_addmcdose: Dose or error matrices do not have the expected format (i.e. cell). Exit now!')
elseif iscell(MCdose)~=1
    error('dicomrt_addmcdose: Dose or error matrices do not have the expected format (i.e. cell). Exit now!')
end

% Add segment's dose
if nargin == 2 % dose and error to be added
    for i=1:size(MCdose,1); % loop over beam
        if iscell(MCdose{i,2})==1 % likely segment contribution
            for j=1:size(MCdose{i,2},2); % loop over segment
                % NOTE: the sum of absolute errors is used to calculate the
                % total absolute error ...
                if i==1 & j==1
                    totalMCdose=MCdose{i,2}{j};
                    totalMCerror_abs=MCerror{i,2}{j}.*MCdose{i,2}{j};
                else
                    totalMCdose=totalMCdose+MCdose{i,2}{j};
                    totalMCerror_abs=totalMCerror_abs+MCerror{i,2}{j}.*MCdose{i,2}{j};
                end
            end % end loop over segments
        else % likely beam contribution
            if i==1 
                totalMCdose=MCdose{i,2};
                totalMCerror_abs=MCerror{i,2}.*MCdose{i,2};
            else
                totalMCdose=totalMCdose+MCdose{i,2};
                totalMCerror_abs=totalMCerror_abs+MCerror{i,2}.*MCdose{i,2};
            end
        end 
    end % end loop over beams
    % ... now we calculate the relative error for the total dose
    totalMCerror=totalMCerror_abs./totalMCdose;
elseif nargin == 1 % only dose to be added
    for i=1:size(MCdose,1); % loop over beam
        if iscell(MCdose{i,2})==1 % likely segment contribution
            for j=1:size(MCdose{i,2},2); % loop over segment
                % NOTE: the sum of absolute errors is used to calculate the
                % total absolute error ...
                if i==1 & j==1
                    totalMCdose=MCdose{i,2}{j};
                else
                    totalMCdose=totalMCdose+MCdose{i,2}{j};
                end
            end % end loop over segments
        else % likely beam contribution
            if i==1
                totalMCdose=MCdose{i,2};
            else
                totalMCdose=totalMCdose+MCdose{i,2};
            end
        end 
    end % end loop over beams
end

if nargin == 1
    totalMCdose=dicomrt_restorevarformat(study_temp,totalMCdose);
else
    totalMCdose=dicomrt_restorevarformat(study_temp,totalMCdose);
    totalMCerror=dicomrt_restorevarformat(studye_temp,totalMCerror);
end