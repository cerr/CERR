function [totaldose,totalerror] = dicomrt_adddose(dose,dose_error)
% dicomrt_adddose(dose,dose_error)
%
% Add beam and or segment's contribution 
% 
% dose and dose_error are two cell arrays with the following structure
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
% [totaldose,totalerror]=dicomrt_adddose(A,B)
%
% add all the 3D MC dose and errors from segments, stored respectively in A and B,  
% and return them in totaldose and totalerror
%
% See also dicomrt_loaddose, dicomrt_read3ddose
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check number of argument
error(nargchk(1,2,nargin));

% Check case and set-up some parameters and variables
if nargin==1
    [study_temp,type_dose,label]=dicomrt_checkinput(dose,1);
    dose=dicomrt_varfilter(study_temp);
else
    [study_temp,type_dose,label]=dicomrt_checkinput(dose,1);
    [studye_temp,type_dose,label]=dicomrt_checkinput(dose_error,1);
    dose=dicomrt_varfilter(study_temp);
    dose_error=dicomrt_varfilter(studye_temp);    
end

% Check case
if nargin==2 & (iscell(dose)~=1 | iscell(dose_error)~=1)
    error('dicomrt_adddose: Dose or error matrices do not have the expected format (i.e. cell). Exit now!')
elseif iscell(dose)~=1
    error('dicomrt_adddose: Dose or error matrices do not have the expected format (i.e. cell). Exit now!')
end

% Add segment's dose
if nargin == 2 % dose and error to be added
    for i=1:size(dose,1); % loop over beam
        if iscell(dose{i,2})==1 % likely segment contribution
            for j=1:size(dose{i,2},2); % loop over segment
                % NOTE: the sum of absolute errors is used to calculate the
                % total absolute error ...
                if i==1 & j==1
                    totaldose=dose{i,2}{j};
                    totalerror_abs=dose_error{i,2}{j}.*dose{i,2}{j};
                else
                    totaldose=totaldose+dose{i,2}{j};
                    totalerror_abs=totalerror_abs+dose_error{i,2}{j}.*dose{i,2}{j};
                end
            end % end loop over segments
        else % likely beam contribution
            if i==1 
                totaldose=dose{i,2};
                totalerror_abs=dose_error{i,2}.*dose{i,2};
            else
                totaldose=totaldose+dose{i,2};
                totalerror_abs=totalerror_abs+dose_error{i,2}.*dose{i,2};
            end
        end 
    end % end loop over beams
    % ... now we calculate the relative error for the total dose
    totalerror=totalerror_abs./totaldose;
elseif nargin == 1 % only dose to be added
    for i=1:size(dose,1); % loop over beam
        if iscell(dose{i,2})==1 % likely segment contribution
            for j=1:size(dose{i,2},2); % loop over segment
                % NOTE: the sum of absolute errors is used to calculate the
                % total absolute error ...
                if i==1 & j==1
                    totaldose=dose{i,2}{j};
                else
                    totaldose=totaldose+dose{i,2}{j};
                end
            end % end loop over segments
        else % likely beam contribution
            if i==1
                totaldose=dose{i,2};
            else
                totaldose=totaldose+dose{i,2};
            end
        end 
    end % end loop over beams
end

if nargin == 1
    totaldose=dicomrt_restorevarformat(study_temp,totaldose);
else
    totaldose=dicomrt_restorevarformat(study_temp,totaldose);
    totalerror=dicomrt_restorevarformat(studye_temp,totalerror);
end