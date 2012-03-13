function BEAMexport = dicomrt_BEAMexport(study,int)
% dicomrt_BEAMexport(study,int)
%
% Export rt plan parameters to BEAM00 compliant input files (beam collimation).
%
% rtplanformc contain plan data coded (warmed) by dicomrt_mcwarm.
%
% Output filename convention:
%
% nameof(rtplanformc)_bnsm
%
% where: nameof(rtplanformc) is the actual name of the input argument rtplanformc
%        bn is beam # n
%        sm is segment # m 
%
% Int is interactive option. If int ~=1 or if int is not given session is not interactive
% and default parameters (e.g. directories names) will be used. If int = 1 the user will 
% be asked to set some parameters.
% Parameters for this specific m file are:
%
% SPCNAM				phase space file name
% BEAM_MODULE			beam module name
%
% Example:
%
% dicomrt_BEAMexport(A)
%
% if A is the rtplanformc for a plan with 3 beams and 1 segment for 1st beam, 2 segments
% for 2nd beam and 3 segments for 3rd beam the command will produce the following files:
% 
% A_b1s1, A_b2s1, A_b2s2, A_b3s1, A_b3s2, A_b3s3
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
%  |          |                | [jawsx nth segment] [jawsy nth segment]| [mlc nth segment] [diff MU]|
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
% See also dicomrt_loaddose, dicomrt_loadct, dicomrt_mcwarm
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check number of argument
error(nargchk(1,2,nargin))

if nargin<=1 
    int=0;
end

rtplanformc=dicomrt_mcwarm(study);

% WARNING: TMS 6.0 DEFINE BEAM LIMITING DEVICE APERTURES AT THE ISOCENTRE AND NOT
%          AT THE DEVICE'S PLANE. IF THIS DEFAULT WILL CHANGE IN FUTURE SOME MINOR
%          CHANGES TO THIS SCRIPT WILL BE REQUIRED

% BEAM module name: this a variable which will be passed to dicomrt_createmcscripts
%
BEAM_MODULE=['BEAM_Clinac21CDIImlc'];

% MAIN Monte Carlo transport control parameters. See BEAM00 manual for details
% MAINtitle % this is defined later since Case study name is a variable
MEDIUM=['AIR521ICRU'];
IWATCH=0;
ISTORE=0;
IRESTART=0;
IO_OPT=0;
IDAT=0;
LATCH_OPTION=0;
IZLAST=1;
% NCASE % this is defined later since NCASE is a variable
IXX=97;
JXX=33;
TIMMAX=500;
IBRSPL=1;       % uniform brem split
NBRSPL=30;      % # of brem photons after splitting (because IBRSPL=1, see BEAM manual for details)
IRRLTT=0;       % e- Russian Roulette no
ICM_SPLIT=0;
%ICM_SPLIT=3;    % split particles crossing top of plane "ICM_SPLIT"; no split in this case
%NSPLIT_PHOT=30; % The photon splitting number
%NSPLIT_ELEC=30; % The electron splitting number
IQIN=9;
ISOURC=21; 
% ISOURC=23; % new ISOURC option: enables BEAM FILTER to make more time-efficient
           % JAWS VARMLM. See new beam.mortran.isource22-23 (ES 2002)
INIT_CM=1;
SPCNAM=['/user/phexternal/phx1pl/cardiff/egs4/BEAM_Clinac21CDI/LA5.egs4phsp1'];
ESTEPE=0;
SMAX=0;
ECUTIN=0.7;
PCUTIN=0.01;
IDORAY=0;
IREJCT_GLOBAL=1;    % Do range rejection (see http://www.irs.inms.nrc.ca/inms/irs/papers/nrc_bench/node10.html)
ESAVE_GLOBAL=2;
IFLUOR=0;
IFORCE=0;
NFMIN=0;
NFMAX=0;
NFCMIN=0;
NFCMAX=0;
NSC_PLANES=1;
IPLANE_to_CM=3;
NSC_ZONES=5;        % 5 scoring regions within phase space file
MZONES_TYPE=0;      % annular socring regions with outer radius defined below
RSCORE_ZONE=[1.0; 2.5; 5.0; 10.0; 20.0];
ITDOSE_ON=0;
Z_min_CM=27.4;

% JAWS Monte Carlo transport control parameters. See BEAM00 manual for details
JAWSdummyline=['****start of Component Module ##1## JAWS is used'];
RMAX_JAWS=10;
JAWSname=['Secondary collimator (JAWS) settings'];
ISCM_MAX_JAWS=2;
XY_CHOICE=['X';'Y'];
ZMIN_JAWS=[28.0;36.7];
ZMAX_JAWS=[35.8;44.5];
% XFP_JAWS % here Y??_JAWS is also introduced for clarity
% XBP_JAWS % these variables are defined later as they vary
% XFN_JAWS % accordingly with rt plan settings
% XBN_JAWS
% BF_XN    % Introduce BEAM FILTER feature for BEAM (ES 2002) 
% BF_XP    % New source named ISOURC=23 was developed.
% BF_YN    % Particles from the phsp file selected outside the area
% BF_YP    % defined by BF_?? will be discarded.
           % these variables are defined later as they vary
           % accordingly with rt plan settings
INT_ECUT_JAWS=0.7;
INT_PCUT_JAWS=0.01;
INT_DOZE_ZONE_JAWS=0;
INT_IREGION_TO_BIT_JAWS=0;
EXT_ECUT_JAWS=0.7;
EXT_PCUT_JAWS=0.01;
EXT_DOSE_ZONE_JAWS=[9;10];
EXT_IREGION_TO_BIT_JAWS=[9;10];
MED_JAWS=['W521ICRU'];

% VARMLM Monte Carlo transport control parameters. See BEAM00 manual for details
VARMLMdummyline=['****start of Component Module ##2## VARMLM is used'];
VARMLMname=['Varian Millenium MLC 80 leaves'];
RMAX_VARMLM=15.0000;
ORIENT_VARMLM=1; % default for Velindre
DESIGN_VARMLM=1; % default for this CM
ZMIN_VARMLM=47.825;
ZTHICK_VARMLM=6.15000;
NUM_LEAF_VARMLM=40;
LEAFWIDTH_VARMLM=0.48000;
START_VARMLM=-9.78000;
WSCREWTOP_VARMLM=0.11600;
HSCREWTOP_VARMLM=0.25600;
WSCREWBOT_VARMLM=0.28000;
HSCREWBOT_VARMLM=0.34900;
WHOOK_VARMLM=0.14000;
HHOOK_VARMLM=0.23300;
WTONGUE_VARMLM=0.06300;
HTONGUE_VARMLM=2.55000;
WGROOVE_VARMLM=0.08000;
HGROOVE_VARMLM=2.95000;
LEAFGAP_VARMLM=0.01000;
ENDTYPE_VARMLM=0;
LEAFRADIUS_VARMLM=8.000000;
ZFOCUS_VARMLM=-55.24240;
INT_ECUT_VARMLM=0.7;
INT_PCUT_VARMLM=0.01;
INT_DOZE_ZONE_VARMLM=0;
INT_IREGION_TO_BIT_VARMLM=20;
INT_MED_VARMLM=['AIR521ICRU'];
EXT_ECUT_VARMLM=0.7;
EXT_PCUT_VARMLM=0.01;
EXT_DOZE_ZONE_VARMLM=0;
EXT_IREGION_TO_BIT_VARMLM=21;
EXT_MED_VARMLM=['W521D175'];
% NEG_VARMLM % these variables are defined later as they vary
% POS_VARMLM % accordingly with rt plan settings
% NUM_VARMLM % parameters below are used for calculating MLC leaves position
MLCPLANE=50.9;
ISOPLANE=100.0;

% SLABS (LIGHT RETICLE) Monte Carlo transport control parameters. See BEAM00 manual for details
SLABSdummyline=['****start of Component Module ##3## SLABS is used'];
SLABSname=['LIGHT RETICLE'];
RMAX_SLABS=15.0;
NUM_SLABS=1;
ZMIN_SLABS=55.64;
ZTHICK_SLABS=0.010;
ECUT_SLABS=0.7;
PCUT_SLABS=0.01;
DOSE_ZONE_SLABS=11;
IREGION_TO_BIT_SLABS=11;
MED_SLABS=['MYLAR521ICRU'];
ENDCMS=['***End of all CMs -- Emiliano Spezi Feb 2002'];

% Calculate # of histories per beam and per segment
% Call function dicomrt_histories 
NCASE=dicomrt_histories(study);
% calculation of # histories completed
% NCASE is a cell array defined within the called function dicomrt_histories
% with the following call NCASE=cell(size(rtplanformc,1),2); 
%
% Reduce of 1/10 the number of particles trasported fro this simulation
% to avoid huge phsp file to be produced. This feature may be turned off
% if ICM_SPLIT ~=0
if ICM_SPLIT~=0
    for i=1:size(NCASE,1)
        NCASE{i}=NCASE{i}/10;
        NCASE{i,2}=NCASE{i,2}/10;
    end
end

% Prepare title and strings for internal file identification
MAINtitle=['MCTP - BEAM00. Case study name: ',inputname(1)];
comma=[','];

% Almost Ready to export: if int==1 start interactive session
if isnumeric(int)==1 &  int==1
    disp(' ');
    disp('Current default for input phase space file is: ');
    disp(SPCNAM);
    phspoption = input('Do you want to change this default path Y/N [N]:','s');
    if phspoption == 'Y' | phspoption == 'y';
        SPCNAM = input('Input the filename complete of full path : ','s');
    end
    disp(' ');
    disp('Current default MC module is: ');
    disp(BEAM_MODULE);
    disp('This information will be used for the creation of links to phsp files');
    egs4option = input('Do you want to change this default path Y/N [N]:','s');
    if egs4option == 'Y' | egs4option == 'y';
        BEAM_MODULE = input('Input the filename complete of full path : ','s');
    end
else
end


% Open log file
time=fix(clock);
logfilename=[inputname(1),'.dcmlog'];
logfileid=fopen(num2str(logfilename),'a+');
fprintf(logfileid,'*****************************************************************************************');
fprintf(logfileid,'\n');
fprintf(logfileid,'Start of dicomrt_BEAMexport session: ');
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

% Export plan into BEAM00 input files for MC calculation
for i=1:size(rtplanformc,1) 
    for j=1:size(rtplanformc{i,3},1) 
        filename=[inputname(1),'_b',int2str(i),'s',int2str(j),'.egs4inp'];
        fid=fopen(filename,'w');
        fprintf(fid,MAINtitle);
        fprintf(fid,'\n');
        fprintf(fid,MEDIUM);
        fprintf(fid,'\n');
        fprintf(fid,'%2i',IWATCH);fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',ISTORE);fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',IRESTART);fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',IO_OPT);fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',IDAT);fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',LATCH_OPTION);fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',IZLAST);fprintf(fid,'%c',comma);
        fprintf(fid,'\n');
        fprintf(fid,'%i',round(NCASE{i,2}(j)));fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',IXX);fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',JXX);fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',TIMMAX);fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',IBRSPL);fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',NBRSPL);fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',IRRLTT);fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',ICM_SPLIT);fprintf(fid,'%c',comma);
        fprintf(fid,'\n');
        if ICM_SPLIT>0
            fprintf(fid,'%3i',NSPLIT_PHOT);fprintf(fid,'%c',comma);
            fprintf(fid,'%3i',NSPLIT_ELEC);fprintf(fid,'%c',comma);
            fprintf(fid,'\n');
        else
        end
        fprintf(fid,'%2i',IQIN);fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',ISOURC);fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',INIT_CM);fprintf(fid,'%c',comma);
        % retrieve settings
        BF_XN=rtplanformc{i,3}{j,1}(1,1)/ISOPLANE*0.1*Z_min_CM*0.1*10*1.5;
        BF_XP=rtplanformc{i,3}{j,1}(2,1)/ISOPLANE*0.1*Z_min_CM*0.1*10*1.5;
        % IEC seetings would be 
        % BF_YN=rtplanformc{i,3}{j,2}(1,1)/ISOPLANE*0.1*Z_min_CM*0.1*10*1.5;
        % BF_YP=rtplanformc{i,3}{j,2}(2,1)/ISOPLANE*0.1*Z_min_CM*0.1*10*1.5;
        % but ... 
        BF_YP=-rtplanformc{i,3}{j,2}(1,1)/ISOPLANE*0.1*Z_min_CM*0.1*10*1.5; % ... because
        BF_YN=-rtplanformc{i,3}{j,2}(2,1)/ISOPLANE*0.1*Z_min_CM*0.1*10*1.5; % Y(IEC)=-Y(BEAM)
        % (Z_min_CM/ZMIN_JAWS(2)*1.5) is a factor which backproject JAWS  
        % settings at phsp plane and increase them of 50%
        fprintf(fid,'%6.4g',BF_XN);fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',BF_XP);fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',BF_YN);fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',BF_YP);fprintf(fid,'%c',comma);
        fprintf(fid,'\n');
        fprintf(fid,SPCNAM);
        fprintf(fid,'\n');
        fprintf(fid,'%6.4g',ESTEPE);fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',SMAX);fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',ECUTIN);fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',PCUTIN);fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',IDORAY);fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',IREJCT_GLOBAL);fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',ESAVE_GLOBAL);fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',IFLUOR);fprintf(fid,'%c',comma);
        fprintf(fid,'\n');
        fprintf(fid,'%2i',IFORCE);fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',NFMIN);fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',NFMAX);fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',NFCMIN);fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',NFCMAX);fprintf(fid,'%c',comma);
        fprintf(fid,'\n');
        fprintf(fid,'%2i',NSC_PLANES);fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',IPLANE_to_CM);fprintf(fid,'%c',comma);
        fprintf(fid,'\n');
        fprintf(fid,'%2i',NSC_ZONES);fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',MZONES_TYPE);fprintf(fid,'%c',comma);
        fprintf(fid,'\n');
        if exist('RSCORE_ZONE')==1
            for k=1:length(RSCORE_ZONE)
                fprintf(fid,'%4.2f',RSCORE_ZONE(k));fprintf(fid,'%c',comma);
            end
            fprintf(fid,'\n');
        end
        fprintf(fid,'%2i',ITDOSE_ON);fprintf(fid,'%c',comma);
        fprintf(fid,'\n');
        fprintf(fid,'%6.4g',Z_min_CM);fprintf(fid,'%c',comma);
        fprintf(fid,'\n'); 
        % main input parameters written
        % start writing JAWS CM settings
        fprintf(fid,JAWSdummyline);
        fprintf(fid,'\n');
        fprintf(fid,'%6.4g',RMAX_JAWS);fprintf(fid,'%c',comma);
        fprintf(fid,'\n');
        fprintf(fid,JAWSname);
        fprintf(fid,'\n');
        fprintf(fid,'%2i',ISCM_MAX_JAWS);fprintf(fid,'%c',comma);
        fprintf(fid,'\n');
        fprintf(fid,XY_CHOICE(2));fprintf(fid,'%c',comma);
        fprintf(fid,'\n');
        fprintf(fid,'%6.4g',ZMIN_JAWS(1));fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',ZMAX_JAWS(1));fprintf(fid,'%c',comma);
        % IEC settings would be
        % YFN_JAWS=rtplanformc{i,3}{j,2}(1,1)/ISOPLANE*0.1*ZMIN_JAWS(1)*10*0.1; % dicom-rt is in mm
        % YBN_JAWS=rtplanformc{i,3}{j,2}(1,1)/ISOPLANE*0.1*ZMAX_JAWS(1)*10*0.1; % Y(IEC)=-Y(BEAM)
        % YFP_JAWS=rtplanformc{i,3}{j,2}(2,1)/ISOPLANE*0.1*ZMIN_JAWS(1)*10*0.1; 
        % YBP_JAWS=rtplanformc{i,3}{j,2}(2,1)/ISOPLANE*0.1*ZMAX_JAWS(1)*10*0.1;
        % but ...        
        YFP_JAWS=-rtplanformc{i,3}{j,2}(1,1)/ISOPLANE*0.1*ZMIN_JAWS(1)*10*0.1; % because 
        YBP_JAWS=-rtplanformc{i,3}{j,2}(1,1)/ISOPLANE*0.1*ZMAX_JAWS(1)*10*0.1; % Y(IEC)=-Y(BEAM)
        YFN_JAWS=-rtplanformc{i,3}{j,2}(2,1)/ISOPLANE*0.1*ZMIN_JAWS(1)*10*0.1; % dicom-rt in in mm 
        YBN_JAWS=-rtplanformc{i,3}{j,2}(2,1)/ISOPLANE*0.1*ZMAX_JAWS(1)*10*0.1;
        fprintf(fid,'%6.4g',YFP_JAWS);fprintf(fid,'%c',comma); 
        fprintf(fid,'%6.4g',YBP_JAWS);fprintf(fid,'%c',comma); 
        fprintf(fid,'%6.4g',YFN_JAWS);fprintf(fid,'%c',comma);  
        fprintf(fid,'%6.4g',YBN_JAWS);fprintf(fid,'%c',comma);   
        fprintf(fid,'\n');
        fprintf(fid,XY_CHOICE(1));fprintf(fid,'%c',comma);
        fprintf(fid,'\n');
        fprintf(fid,'%6.4g',ZMIN_JAWS(2));fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',ZMAX_JAWS(2));fprintf(fid,'%c',comma);
        XFN_JAWS=rtplanformc{i,3}{j,1}(1,1)/ISOPLANE*0.1*ZMIN_JAWS(2)*10*0.1;
        XBN_JAWS=rtplanformc{i,3}{j,1}(1,1)/ISOPLANE*0.1*ZMAX_JAWS(2)*10*0.1;
        XFP_JAWS=rtplanformc{i,3}{j,1}(2,1)/ISOPLANE*0.1*ZMIN_JAWS(2)*10*0.1;
        XBP_JAWS=rtplanformc{i,3}{j,1}(2,1)/ISOPLANE*0.1*ZMAX_JAWS(2)*10*0.1;
        fprintf(fid,'%6.4g',XFP_JAWS);fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',XBP_JAWS);fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',XFN_JAWS);fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',XBN_JAWS);fprintf(fid,'%c',comma);
        fprintf(fid,'\n');
        fprintf(fid,'%6.4g',INT_ECUT_JAWS);fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',INT_PCUT_JAWS);fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',INT_DOZE_ZONE_JAWS);fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',INT_IREGION_TO_BIT_JAWS);fprintf(fid,'%c',comma);
        fprintf(fid,'\n');
        fprintf(fid,'%6.4g',EXT_ECUT_JAWS);fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',EXT_PCUT_JAWS);fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',EXT_DOSE_ZONE_JAWS(1));fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',EXT_IREGION_TO_BIT_JAWS(1));fprintf(fid,'%c',comma);
        fprintf(fid,'\n');
        fprintf(fid,MED_JAWS);
        fprintf(fid,'\n');
        fprintf(fid,'%6.4g',EXT_ECUT_JAWS);fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',EXT_PCUT_JAWS);fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',EXT_DOSE_ZONE_JAWS(2));fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',EXT_IREGION_TO_BIT_JAWS(2));fprintf(fid,'%c',comma);
        fprintf(fid,'\n');
        fprintf(fid,MED_JAWS);
        fprintf(fid,'\n'); 
        % JAWS CM settings written
        % start writing VARMLM CM settings
        fprintf(fid,VARMLMdummyline);
        fprintf(fid,'\n');
        fprintf(fid,'%6.4g',RMAX_VARMLM);fprintf(fid,'%c',comma);
        fprintf(fid,'\n');
        fprintf(fid,VARMLMname);
        fprintf(fid,'\n');
        fprintf(fid,'%2i',ORIENT_VARMLM);fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',DESIGN_VARMLM);fprintf(fid,'%c',comma);
        fprintf(fid,'\n');
        fprintf(fid,'%6.4g',ZMIN_VARMLM);fprintf(fid,'%c',comma);
        fprintf(fid,'\n');
        fprintf(fid,'%6.4g',ZTHICK_VARMLM);fprintf(fid,'%c',comma);
        fprintf(fid,'\n');
        fprintf(fid,'%3i',NUM_LEAF_VARMLM);fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',LEAFWIDTH_VARMLM);fprintf(fid,'%c',comma);
        fprintf(fid,'\n');
        fprintf(fid,'%6.4g',START_VARMLM);fprintf(fid,'%c',comma);
        fprintf(fid,'\n');
        fprintf(fid,'%6.4g',WSCREWTOP_VARMLM);fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',HSCREWTOP_VARMLM);fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',WSCREWBOT_VARMLM);fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',HSCREWBOT_VARMLM);fprintf(fid,'%c',comma);
        fprintf(fid,'\n');
        fprintf(fid,'%6.4g',WHOOK_VARMLM);fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',HHOOK_VARMLM);fprintf(fid,'%c',comma);
        fprintf(fid,'\n');
        fprintf(fid,'%6.4g',WTONGUE_VARMLM);fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',HTONGUE_VARMLM);fprintf(fid,'%c',comma);
        fprintf(fid,'\n');
        fprintf(fid,'%6.4g',WGROOVE_VARMLM);fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',HGROOVE_VARMLM);fprintf(fid,'%c',comma);
        fprintf(fid,'\n');
        fprintf(fid,'%6.4g',LEAFGAP_VARMLM);fprintf(fid,'%c',comma);
        fprintf(fid,'\n');
        fprintf(fid,'%2i',ENDTYPE_VARMLM);fprintf(fid,'%c',comma);
        fprintf(fid,'\n');
        fprintf(fid,'%6.4g',LEAFRADIUS_VARMLM);fprintf(fid,'%c',comma);
        fprintf(fid,'\n');
        fprintf(fid,'%6.4g',ZFOCUS_VARMLM);fprintf(fid,'%c',comma);
        fprintf(fid,'\n');
        NEG_VARMLM=rtplanformc{i,4}{j,1}(1:40)*0.1*MLCPLANE/ISOPLANE;
        POS_VARMLM=rtplanformc{i,4}{j,1}(41:80)*0.1*MLCPLANE/ISOPLANE;
        NEG_VARMLM=flipdim(NEG_VARMLM,1);
        POS_VARMLM=flipdim(POS_VARMLM,1);
        for k=1:size(NEG_VARMLM,1); 
            fprintf(fid,'%6.4g',NEG_VARMLM(k));fprintf(fid,'%c',comma);% because:
            fprintf(fid,'%6.4g',POS_VARMLM(k));fprintf(fid,'%c',comma);% Y(IEC)=-Y(BEAM)
            fprintf(fid,'\n');
        end
        fprintf(fid,'%6.4g',INT_ECUT_VARMLM);fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',INT_PCUT_VARMLM);fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',INT_DOZE_ZONE_VARMLM);fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',INT_IREGION_TO_BIT_VARMLM);fprintf(fid,'%c',comma);
        fprintf(fid,'\n');
        fprintf(fid,INT_MED_VARMLM);
        fprintf(fid,'\n');
        fprintf(fid,'%6.4g',EXT_ECUT_VARMLM);fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',EXT_PCUT_VARMLM);fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',EXT_DOZE_ZONE_VARMLM);fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',EXT_IREGION_TO_BIT_VARMLM);fprintf(fid,'%c',comma);
        fprintf(fid,'\n');
        fprintf(fid,EXT_MED_VARMLM);
        fprintf(fid,'\n'); 
        % VARMLM CM settings written
        % start writing SLABS CM settings
        fprintf(fid,SLABSdummyline);
        fprintf(fid,'\n');
        fprintf(fid,'%6.4g',RMAX_SLABS);fprintf(fid,'%c',comma);
        fprintf(fid,'\n');
        fprintf(fid,SLABSname);
        fprintf(fid,'\n');
        fprintf(fid,'%2i',NUM_SLABS);fprintf(fid,'%c',comma);
        fprintf(fid,'\n');
        fprintf(fid,'%6.4g',ZMIN_SLABS);fprintf(fid,'%c',comma);
        fprintf(fid,'\n');
        fprintf(fid,'%6.4g',ZTHICK_SLABS);fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',ECUT_SLABS);fprintf(fid,'%c',comma);
        fprintf(fid,'%6.4g',PCUT_SLABS);fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',DOSE_ZONE_SLABS);fprintf(fid,'%c',comma);
        fprintf(fid,'%2i',IREGION_TO_BIT_SLABS);fprintf(fid,'%c',comma);
        fprintf(fid,'\n');
        fprintf(fid,MED_SLABS);
        fprintf(fid,'\n');
        fprintf(fid,ENDCMS);
        fprintf(fid,'\n');
        fclose(fid);
        % SLABS CM settings written 
        % Continue with log file
        fprintf(logfileid,'%s',filename);fprintf(logfileid,'\t');
        fprintf(logfileid,'%6.4g',rtplanformc{i,4}{j,2});fprintf(logfileid,'\t');
        fprintf(logfileid,'%i',round(NCASE{i,2}(j)));
        fprintf(logfileid,'\n');
    end
end

% Link file
disp(' ');
disp(' To create script for automatic link of phsp file use dicomrt_createmclinks(rtplanformc,BEAM_MODULE)');
%disp(' ');
%linkoption = input('Do you want script for automatic link of phsp file to be created now ? Y/N [N]:','s');
%if linkoption == 'Y' | linkoption == 'y';
%    dicomrt_createmclinks(rtplanformc,BEAM_MODULE,inputname(1));
%    fprintf(logfileid,' Script for linking phsp file was created');
%    fprintf(logfileid,'\n');
%end

% Close log file
fclose(logfileid);

