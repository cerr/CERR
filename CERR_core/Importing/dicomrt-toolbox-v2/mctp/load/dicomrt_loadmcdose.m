function [cellMCdose,cellMCerror] = dicomrt_loadmcdose(study,int)
% dicomrt_loadmcdose(study,int)
%
% Import Monte Carlo 3D dose distribution calculated for current study.
% 
% It is possible to keep segment's 3D dose answering 'Y' to a dialog question.
% Answering 'Y' will return in MCdose and in MCerror two cell arrays with the following structure
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
% Int is interactive option. If int ~=1 or if int is not given session is not interactive
% and default parameters (e.g. directories names) will be used. If int = 1 the user will 
% be asked to set some parameters.
% Parameters for this specific m file are:
%
% DOSEDIR				directory where 3ddose files are located
% CELLStore			    option to store individual segments or clear them after use 
%
% Example:
%
% [MCdose,MCerror]=dicomrt_loadmcdose(A)
%
% load all the DOSXYZ 3ddose files and store dose in MCdose and relative error in MCerror
%
% See also dicomrt_read3ddose, dicomrt_loaddose, dicomrt_backscatter
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check number of argument
error(nargchk(1,2,nargin))

if nargin<=1 
    int=0;
end

% Check input
[study,type]=dicomrt_checkinput(study);

if isequal(type,'RTPLAN')==1
    % RTPLAN info
    rtplan=study{1,1}{1};
    % Compacting data
    rtplanformc=dicomrt_mcwarm(study);
else
    error('dicomrt_loadmcdose: input study is not RTPLAN type. Exit now!');
end

% Default directory where ctphantom is stored: if int==1 start interactive session
if isnumeric(int)==1 &  int==1
    option = input('Do you want to change the default dir for 3ddose files (./) Y/N [N]: ','s'); 
    if option == 'Y' | option == 'y';
        DOSEDIR = input('Input the full path for 3ddose files : ','s');
        DOSEDIR = [DOSEDIR,'/'];
    end
else
    option = 'N';
end

% Initialize variable for STORE option
CELLStore = 0;

% STORE individual segments or clear them after use option
% if int==1 start interactive session
if isnumeric(int)==1 &  int==1
    disp('Do you want to:');
    disp('(1) load the dose matrix as a sum of all beams [default]');
    disp('(2) keep individual beam dose contribution');
    disp('(3) keep individual segment dose contribution');
    STOREoption = input('Option: ');
    if STOREoption >= 2 
        CELLStore = 1;
        cell_dose = cell(size(rtplanformc,1),2);
        cell_error = cell(size(rtplanformc,1),2);
    else
        CELLStore = 0;
    end
else
    STOREoption = 'N';
end

% [dose/part] to [dose/MU] conversion factor F
% determined from the followinf formula:
% ADMC [Gy/part] * F = ADMeas [Gy/MU]
%
% where ADMC = Average dose from MC between 5 and 15 cm deep
%       ADMeas = Average measured dose between 5 and 15 cm deep
F=8.7502e+013; % The value was obtained from calibration experiment with the following BEAM parameters:
%               NBRSPL=30;      % # of brem photons after splitting (because IBRSPL=1, see BEAM manual for details)
%               IRRLTT=0;       % e- Russian Roulette no 
%               IREJCT_GLOBAL=1;% range rejection yes using ESAVE_GLOBAL below
%               ESAVE_GLOBAL=2; % 
%               ESTEPE=0;
%               SMAX=0;
%               ECUTIN=0.7;
%               PCUTIN=0.01;
%
%               and DOSXYZ parameters:
%               ECUTIN=0.700;
%               PCUTIN=0.01;
%               SMAX=0;
%               ESTEPE:0.25;
%               DSURROUND=[60,0,0,0];
%
%               Standard and "ad-hoc" built materials  were taken from 521icru.pegs4dat.
%               See dicomrt_BEAMexport and dicomrt_DOSXYZexport for further details.

%               
% Get Patient Position: 
PatientPosition=dicomrt_getPatientPosition(rtplanformc);

% Retrieve backscatter factor data for this study
% 
% NOTE: MC dose calculation need to be corrected for backscatter into the monitor chamber.
% The above MU calibration factor (F) was calculated in reference conditions. 
% The dose distribution was normalised to the total incident particles from original source.
% When dose distributions are calulated from different fields sizes scatter conditions change.
% This affect the total number of incident particles from original source and the MC dose calculation.
% For this reason the effect of the backscatter into the monitor chamber needs to be taken into account.
%
bsf=dicomrt_backscatter(rtplanformc);

% Counting total number of segments
totsegments=0;
currentsegment=0;
for i=1:size(rtplanformc,1)
    for j=1:size(rtplanformc{i,3},1);
        totsegments=totsegments+1;
    end
end

% Progress bar
h = waitbar(0,['Loading progress:']);
set(h,'Name','dicomrt_loadmcdose: loading MC dose array');

% Import 3D dose into DOSXYZ00 input files for MC calculation
if CELLStore ==0; % retrieve total dose
    for i=1:size(rtplanformc,1) % loop over beams
        for j=1:size(rtplanformc{i,3},1); % loop over segments
            % update current segment for progress bar
            currentsegment=currentsegment+1;
            if option == 'Y' | option == 'y';
                filename=[DOSEDIR,inputname(1),'_xyz_b',int2str(i),'s',int2str(j),'.3ddose'];
            else
                filename=[inputname(1),'_xyz_b',int2str(i),'s',int2str(j),'.3ddose'];
            end
            [dose,derror]=dicomrt_read3ddose(PatientPosition,filename);
            % convert dose/part into dose/MU
            dose=dose*F;
            % now convert dose/MU into dose (Gy)
            dose=dose*rtplanformc{i,4}{j,2};
            % add the effect of the backscattter into the monitor chamber 
            dose=dose./bsf{i,2}{j};
            % so far dose was dose/fraction
            % now convert it in total dose
            dose=dose*rtplanformc{i,2}(10);
            % NOTE: the sum of absolute errors is used to calculate the
            % total absolute error ...
            if i==1 & j==1
                MCdose=dose;
                MCerror_abs=derror.*dose;
            else
                MCdose=MCdose+dose;
                MCerror_abs=MCerror_abs+derror.*dose;
            end
            waitbar(currentsegment/totsegments,h);
        end % end loop over segments
    end %end loop over beams
    % ... now we calculate the relative error for the total dose
    MCerror=MCerror_abs./MCdose;
else
    if STOREoption==2 % keep beam contribution
        for i=1:size(rtplanformc,1); % loop over beam
            cell_dose{i} = rtplanformc{i};
            cell_error{i} = rtplanformc{i};
            for j=1:size(rtplanformc{i,3},1); % loop over segment
                % update current segment for progress bar
                currentsegment=currentsegment+1;
                if option == 'Y' | option == 'y';
                    filename=[DOSEDIR,inputname(1),'_xyz_b',int2str(i),'s',int2str(j),'.3ddose'];
                else
                    filename=[inputname(1),'_xyz_b',int2str(i),'s',int2str(j),'.3ddose'];
                end
                [dose,derror]=dicomrt_read3ddose(PatientPosition,filename);
                % convert dose/part into dose/MU
                dose=dose*F;
                % now convert dose/MU into dose (Gy)
                dose=dose*rtplanformc{i,4}{j,2};
                % add the effect of the backscattter into the monitor chamber 
                dose=dose./bsf{i,2}{j};
                % so far dose was dose/fraction
                % now convert it in total dose
                dose=dose*rtplanformc{i,2}(10);
                if j==1
                    beam_dose=dose;
                    beam_error_abs=derror.*dose;
                else
                    beam_dose=beam_dose+dose;
                    beam_error_abs=beam_error_abs+derror.*dose;
                end
                waitbar(currentsegment/totsegments,h);
            end % end loop over segments
            cell_dose{i,2} = beam_dose;
            cell_error{i,2} = beam_error_abs./beam_dose;
            clear beam_dose;
            clear beam_error_abs;
        end %end loop over beams
        % Return the cell array
        MCdose=cell_dose;
        MCerror=cell_error;
    elseif STOREoption==3 % keep segments contribution
        for i=1:size(rtplanformc,1); % loop over beam
            cell_dose{i} = rtplanformc{i};
            cell_error{i} = rtplanformc{i};
            for j=1:size(rtplanformc{i,3},1); % loop over segment
                % update current segment for progress bar
                currentsegment=currentsegment+1;
                if option == 'Y' | option == 'y';
                    filename=[DOSEDIR,inputname(1),'_xyz_b',int2str(i),'s',int2str(j),'.3ddose'];
                else
                    filename=[inputname(1),'_xyz_b',int2str(i),'s',int2str(j),'.3ddose'];
                end
                [dose,derror]=dicomrt_read3ddose(PatientPosition,filename);
                % convert dose/part into dose/MU
                dose=dose*F;
                % now convert dose/MU into dose (Gy)
                dose=dose*rtplanformc{i,4}{j,2};
                % add the effect of the backscattter into the monitor chamber 
                dose=dose./bsf{i,2}{j};
                % so far dose was dose/fraction
                % now convert it in total dose
                dose=dose*rtplanformc{i,2}(10);
                %
                cell_dose{i,2}{j} = dose;
                cell_error{i,2}{j} = derror;
                waitbar(currentsegment/totsegments,h);
            end % end loop over segments
        end %end loop over beams
        % Return the cell array
        MCdose=cell_dose;
        MCerror=cell_error;
    end
end

% Label Plan as MCDOSE and update time of creation
study{1,1}{1}.RTPlanLabel=[rtplan.RTPlanLabel,'-MCDOSE'];
study{1,1}{1}.RTPlanDate=date;
time=fix(clock);
creationtime=[num2str(time(4)),':',num2str(time(5))];
study{1,1}{1}.RTPlanTime=creationtime;

% Create cell array and store data
cellMCdose=cell(3,1);
cellMCdose{1,1}=study{1,1};
cellMCdose{2,1}=MCdose;
cellMCdose{3,1}=rtplanformc;

cellMCerror=cell(3,1);
cellMCerror{1,1}=study{1,1};
cellMCerror{2,1}=MCerror;
cellMCerror{3,1}=rtplanformc;

% Close progress bar
close(h);
