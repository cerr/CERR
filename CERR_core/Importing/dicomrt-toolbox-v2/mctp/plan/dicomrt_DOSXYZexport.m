function dicomrt_DOSXYZexport(study,phantfilename,int)
% dicomrt_DOSXYZexport(study,phantfilename,int)
%
% Export rt plan parameters to DOSXYZ00 compliant input files.
%
% Filename "phantfilename" is the filename (no extension) of the ctphantom used 
%    for the MC calculation    
% Default path to "phantfilename" is /omega/espezi/egs4/dosxyz but the user is given the 
%    possibility to change this default.
%
% Output filename convention:
%
% nameof(rtplanformc)_xyz_bnsm
%
% where: nameof(rtplanformc) is the actual name of the input argument rtplanformc
%        bn is beam # n
%        sm is segment # m 
%
% Int is an OPTIONAL parameter for interactive session. 
%    If int ~=1 or if int is not given session is not interactive
%    and default parameters (e.g. directories names) will be used. If int = 1 the user will 
%    be asked to set some parameters.
% 
% Parameters for this specific m file are:
%
% PHANTFILEDIR			directory where ct phantom is located
%
% Example:
%
% dicomrt_DOSXYZexport(A,filename)
%
% if A is the rtplanformc for a plan with 3 beams and 1 segment for 1st beam, 2 segments
% for 2nd beam and 3 segments for 3rd beam the command will produce the following files:
% 
% A_xyz_b1s1, A_xyz_b2s1, A_xyz_b2s2, A_xyz_b3s1, A_xyz_b3s2, A_xyz_b3s3
%
% All files will refer to the ctphantom specified by phantfilename.
%
% A file called nameof(rtplanformc).dcmlog will be also produced in the working directory. 
% nameof(rtplanformc).dcmlog contains useful information such us time and date of the export
% session and "FILENAME","DIFF MU","# PARTICLES" of each segment.It can be imported in spreadsheets 
% and used to check the study's parameters. Different session's logs will bea appended to the file.
%
% rtplanformc is a cell array with the following structure
%
%   beam name   common beam            primary collimator position         MLC and MU
%                  data
%  ---------------------------------------------------------------------------------------------------
%  | [beam 1] |gantry angle    | [jawsx 1st segment] [jawsy 1st segment]| [mlc 1st segment] [diff MU]|
%  |          |coll angle      |----------------------------------------------------------------------
%  |          |iso position (3)| [jawsx 2nd segment] [jawsy 2nd segment]| [mlc 2nd segment] [diff MU]|
%  |          |StBLD dist   (3)|----------------------------------------------------------------------
%  |          |voxel dim       |                   ...                  |             ...            |
%  |          |patient position|---------------------------------------------------------------------- 
%  |          |                |[jawsx nth segment] [jawsy nth segment]| [mlc nth segment] [diff MU]|
%  ---------------------------------------------------------------------------------------------------
%  |               ...                                    ...                                ...               
%  ---------------------------------------------------------------------------------------------------
%  | [beam n] |gantry angle    | [jawsx 1st segment] [jawsy 1st segment]| [mlc 1st segment] [diff MU]|
%  |          |coll angle      |----------------------------------------------------------------------
%  |          |iso position (3)| [jawsx 2nd segment] [jawsy 2nd segment]| [mlc 2nd segment] [diff MU]|
%  |          |StBLD dist   (3)|----------------------------------------------------------------------
%  |          |voxel dim       |                   ...                  |             ...            |
%  |          |patient position|---------------------------------------------------------------------- 
%  |          |                | [jawsx nth segment] [jawsy nth segment]| [mlc nth segment] [diff MU]|
%  ---------------------------------------------------------------------------------------------------
%
% See also dicomrt_loaddose, dicomrt_loadct, dicomrt_mcwarm, dicomrt_BEAMexport
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check number of argument
error(nargchk(2,3,nargin))

if nargin<=2 
    int=0;
end

rtplanformc=dicomrt_mcwarm(study);

% Check phantfilename: it cannot be a variable
if ischar(phantfilename)~=1, error('dicomrt_DOSXYZexport: Second arguments must be a character string. Exit now!'); end

% WARNING: TMS 6.0 DEFINE BEAM LIMITING DEVICE APERTURES AT THE ISOCENTRE AND NOT
%          AT THE DEVICE'S PLANE. IF THIS DEFAULT WILL CHANGE IN FUTURE SOME MINOR
%          CHANGES TO THIS SCRIPT WILL BE REQUIRED

% BEAM module name: this a variable which will be passed to dicomrt_createmcscripts
%
MC_MODULE=['dosxyz'];

% MAIN Monte Carlo transport control parameters. See DOSXYZ00 manual for details
% MAINtitle % this is defined later since Case study name is a variable
EMPTY=' '; % empty character used for compatibility with xyz_gui
NMED=0;
ECUTIN=0.700;
PCUTIN=0.01;
SMAX=0;
ZEROAIRDOSE=0; % leave dose in air !
DOSEPRINT=0;
DOSEMAX20=1;
IQIN=2;
ISOURCE=2;
%PHANTFILENAME; % this is defined later since it is a rt plan variable
                % file dir is defined: default to user's dosxyz dir
PHANTFILEDIR=['/user/phexternal/phx1pl/cardiff/'];
%XISO; % these are defined later since they are rt plan variables
%YISO;
%ZISO;
THETAdef=90; % default for coplanar treatment!
PHIdef=-90;  % default: defined for coplanar treatment when gantry andgle = 0 
PHICOLdef=-90; % and collimator angle = 0
ZMIN_VARMLM=47.825; % these variables are the same used for dicomrt_BEAMexport
MLCPLANE=50.9;      % here they are used for the calculation of DSOURCE
ISOPLANE=100.0;     % some redundancy is possible
ZTHICK_VARMLM=6.15000;
DSOURCE=ISOPLANE-(ZMIN_VARMLM+ZTHICK_VARMLM);
ENFLAG=2;
MODE=2;
MEDSUR=1;
DSURROUND=[60,0,0,0];
DFLAG=0;
%NCASE % this is defined later since NCASE is a rt plan variable
IWATCH=0;
ISTORE=0;
TIMMAX=500;
IXX=97;
JXX=33;
BEAM_SIZE=100.0; % this is defined later since BEAM_SIZE is a rt plan variable
ISMOOTH=0;
IRESTART=0;
IDAT=1; % do not write .egs4dat for restart
IREJECT=0;
ESAVE_GLOBAL=0;
NRCYCL=0;
IPARALLEL=-1;
PARNUM=0;
PRESTA_INPUT=[0,0,0,0,0];
%PHSPFILENAME  % this is defined later since FILENAME is a rt plan variable
              % file dir is defined instead as phsp file directory is a parameter
              % phsp files are suppose to be linked into this directory to avoid
              %  PHSPFILENAME being longer than 80 character supported by BEAM/DOSXYZ
PHSPFILEDIR=['/user/phexternal/phx1pl/cardiff/'];

% Calculate # of histories per beam and per segment
% Call function dicomrt_histories 
NCASE=dicomrt_histories(study);
% calculation of # histories completed
% NCASE is a cell array defined within the called function dicomrt_histories
% with the following call NCASE=cell(size(rtplanformc,1),2); 

% Prepare title and strings for internal file identification
MAINtitle=['MCTP - DOSXYZ00. Case study name: ',inputname(1)];
comma=[','];

% Open log file
time=fix(clock);
logfilename=[inputname(1),'.dcmlog'];
logfileid=fopen(num2str(logfilename),'a+');
fprintf(logfileid,'*****************************************************************************************');
fprintf(logfileid,'\n');
fprintf(logfileid,'Start of dicomrt_DOSXYZexport session: ');
fprintf(logfileid,date);fprintf(logfileid,'%c',comma);
fprintf(logfileid,'%2i',time(4));
fprintf(logfileid,'%c',':');
fprintf(logfileid,'%2i',time(5));
fprintf(logfileid,'\n');
fprintf(logfileid,MAINtitle);
fprintf(logfileid,'\n');
fprintf(logfileid,'*****************************************************************************************');
fprintf(logfileid,'\n');
fprintf(logfileid,'%s','FILENAME');fprintf(logfileid,'\t');
fprintf(logfileid,'%s','DIFF MU');fprintf(logfileid,'\t');
fprintf(logfileid,'%s','# PARTICLES');
fprintf(logfileid,'\n');

% Default directory where ctphantom is stored: if int==1 start interactive session
if isnumeric(int)==1 &  int==1
    disp('Default path for ctphantom is: ');
    disp(PHANTFILEDIR);
    option = input('Do you want to change this default ? Y/N [N]: ','s'); 
    if option == 'Y' | option == 'y';
        PHANTFILEDIR = input('Input the full path for ctphantom : ','s');
        PHANTFILEDIR = [PHANTFILEDIR,'/'];
    end
else
end

% Default for checking error in Patient Position
position_not_supported=0;
% Export plan into DOSXYZ00 input files for MC calculation
for i=1:size(rtplanformc,1) 
    for j=1:size(rtplanformc{i,3},1)        
        filename=[inputname(1),'_xyz_b',int2str(i),'s',int2str(j),'.egs4inp'];
        fid=fopen(filename,'w');
        fprintf(fid,MAINtitle);
        fprintf(fid,'\n');
        fprintf(fid,'%2i',NMED);fprintf(fid,'%c',comma);
        fprintf(fid,'\n');
        PHANTFILENAME=[PHANTFILEDIR,phantfilename,'.egs4phant'];
        fprintf(fid,PHANTFILENAME);
        fprintf(fid,'\n');
        fprintf(fid,'%6.4g',ECUTIN);fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',PCUTIN);fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',SMAX);fprintf(fid,'%c',comma);
        fprintf(fid,'\n');
        fprintf(fid,'%2i',ZEROAIRDOSE);fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',DOSEPRINT);fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',DOSEMAX20);fprintf(fid,'%c',comma);
        fprintf(fid,'\n');
        fprintf(fid,'%2i',IQIN);fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',ISOURCE);fprintf(fid,'%c',comma);
        THETA=THETAdef;
        PatientPosition=dicomrt_getPatientPosition(rtplanformc);
        if PatientPosition == 1 % supported Patient Position: HFS
            PHI=PHIdef+rtplanformc{i,2}(1);
            PHICOL=PHICOLdef-rtplanformc{i,2}(2);
        elseif PatientPosition == 2 % supported Patient Position: FFS
            PHI=PHIdef-rtplanformc{i,2}(1);
            PHICOL=PHICOLdef-rtplanformc{i,2}(2)-180;
        elseif PatientPosition == 3 % supported Patient Position: HFP
            PHI=PHIdef+rtplanformc{i,2}(1)-180;
            PHICOL=PHICOLdef-rtplanformc{i,2}(2);
        elseif PatientPosition == 4 % unsupported Patient Position: FFP
            PHI=PHIdef-rtplanformc{i,2}(1)-180;
            PHICOL=PHICOLdef-rtplanformc{i,2}(2)-180;
        else
            position_not_supported=1;
            error('dicomrt_DOSXYZexport: Unable to parse Patient Potition. Exit now!');
        end
        XISO=rtplanformc{i,2}(3)/10; % dicom-rt is in mm
        YISO=rtplanformc{i,2}(4)/10;
        ZISO=rtplanformc{i,2}(5)/10;
        fprintf(fid,'%6.4g',XISO);fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',YISO);fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',ZISO);fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',THETA);fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',PHI);fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',DSOURCE);fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',PHICOL);fprintf(fid,'%c',comma);
        fprintf(fid,'%c',EMPTY);fprintf(fid,'%c',comma);
        fprintf(fid,'\n');
        fprintf(fid,'%2i',ENFLAG);fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',MODE);fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',MEDSUR);fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',DSURROUND(1));fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',DFLAG);fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',DSURROUND(2));fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',DSURROUND(3));fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',DSURROUND(4));fprintf(fid,'%c',comma);
        fprintf(fid,'\n');
        PHSPFILENAME=[inputname(1),'_b',int2str(i),'s',int2str(j),'.egs4phsp1'];
        PHSPFILENAME=[PHSPFILEDIR,PHSPFILENAME];
        fprintf(fid,PHSPFILENAME);
        fprintf(fid,'\n');
        % from dosxyz.mortran:
        % read(5,'(2I10,F15.0,2I10,F15.0,4I10,F15.0,3I10)')
        fprintf(fid,'%i',round(NCASE{i,3}(j)));fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',IWATCH);fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',TIMMAX);fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',IXX);fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',JXX);fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',BEAM_SIZE);fprintf(fid,'%c',comma);        
        fprintf(fid,'%2i',ISMOOTH);fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',IRESTART);fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',IDAT);fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',IREJECT);fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',ESAVE_GLOBAL);fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',NRCYCL);fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',IPARALLEL);fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',PARNUM);fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',PARNUM);fprintf(fid,'%c',comma);
        fprintf(fid,'\n');
        fprintf(fid,'%2i',PRESTA_INPUT(1));fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',PRESTA_INPUT(2));fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',PRESTA_INPUT(3));fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',PRESTA_INPUT(4));fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',PRESTA_INPUT(5));fprintf(fid,'%c',comma);
        fprintf(fid,'\n');
        fclose(fid);
        % Continue with log file
        fprintf(logfileid,'%s',filename);fprintf(logfileid,'\t');
        fprintf(logfileid,'%6.4g',rtplanformc{i,4}{j,2});fprintf(logfileid,'\t');
        fprintf(logfileid,'%i',round(NCASE{i,3}(j)));
        fprintf(logfileid,'\n');
    end
end

if position_not_supported == 1
    warning('dicomrt_DOSXYZexport: The following error occurred while exporting data: Patient Position is not supported. ');
    warning('dicomrt_DOSXYZexport: Do not export and/or use these data unless you know what you are doing');
end
  
% Close log file
fclose(logfileid);
