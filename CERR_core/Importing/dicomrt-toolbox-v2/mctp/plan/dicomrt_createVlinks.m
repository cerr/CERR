function dicomrt_createVlinks = dicomrt_createVlinks(rtplanformc,Vrtplan)
% dicomrt_createVlinks(rtplanformc,Vrtplan)
%
% Create links from original MC 3ddose files and directory to a different filename group
% and directory. This is useful for verification studies beam by beam and segment by segment 
% in water phantoms.
%
% rtplanformc is the rtplan dataset as created by dicomrt_mcwarm
% Vrtplan is the generic name given to the new rtplan (without beam and segment number)
%
% Example:
% 
% Suppose you already imported your rtplan with the command:
%
% [demo2_v1,dose_xmesh,dose_ymesh,dose_zmesh]=dicomrt_loaddose('demo2_v1_rtdose.txt');
%
% your 3ddose files will have the following name convention:
% demo2_v1_bNsM.3ddose, where N in the beam number and M the segment number.
%
% if you now have planned to verify beam by beam and segment by segment your TPS dose distribution
% you can still use your old 3ddose files using the following procedure:
%
% 1) Load the individual segment plan (to repeat for each segment with incremental indexing)
% [demo2_v2_b1s1,dose_xmesh,dose_ymesh,dose_zmesh]=dicomrt_loaddose('rtplan_b1s1');
% 2) Prepare mc data (to repeat for each segment with incremental indexing):
% demo2_v2_b1s1_mc=dicomrt_mcwarm(demo2_v2_b1s1);
% at this point the toolbox expect to find the 3ddose file demo2_v2_b1s1_mc_b1s1.3ddose
% 3) Link your old 3ddose file to the new filename group (automatically done for all the beam and segments) 
% dicomrt_createVlinks(demo2_v1,'demo2_v2')
%
% will create:
%
% demo2_v1.createVlinks     when executed links old 3ddose files from original store directory
%                           to new 3ddose files in the same or user defined directory e.g.:
%
% demo2_v2_mc_b1s1_mc_xyz_b1s1.3ddose --> demo2_v1_mc_xyz_b1s1.3ddose
% demo2_v2_mc_b1s2_mc_xyz_b1s1.3ddose --> demo2_v1_mc_xyz_b1s2.3ddose
% ...
% demo2_v2_mc_bNsM_mc_xyz_b1s1.3ddose --> demo2_v1_mc_xyz_bNsM.3ddose
% 
%
% (hopefully easier than DIY or than start a new MC simulation!).
%
% NOTE1: Vrtplanformc can be either a character string or a variable name.
% NOTE2: the script assume that you used the above name convention for demo2_v2 rtaplan studies
%
%
% See also dicomrt_mcwarm, dicomrt_loadmcdose, dicomrt_createmclinks
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org)

% Check number of arguments
if nargin < 2, error('dicomrt_createVlinks: Error, number of arguments is not sufficient. Exit now!'); end

% Check cases
if iscell(rtplanformc)~=1
   error('dicomrt_createVlinks: Input is not a valid argument. Exit now!');
   return
end

if size(rtplanformc,2)~=5
   error('dicomrt_createVlinks: Input does not have valid dimensions. Exit now!');
   return
end

% Default directories
LOCAL_3DDOSE=['mcdose'];
NEW_3DDOSE=['mcdose'];

% Almost ready to write link file: ask some question
disp(' ');
disp('Current default for local 3ddose directory is: ');
disp(LOCAL_3DDOSE);
doseoption = input('Do you want to change this default path Y/N [N]:','s');
if doseoption == 'Y' | doseoption == 'y';
    LOCAL_3DDOSE = input('Input the filename complete of full path : ','s');
end

ORIGDIR=[LOCAL_3DDOSE,'/'];

% NEW_3DDOSE is the directory where 3ddose files are suppose to be linked 
disp(' ');
disp('Current directory where 3ddose files will be linked is: ');
disp(NEW_3DDOSE);
linkoption = input('Do you want to change this default path Y/N [N]:','s');
if linkoption == 'Y' | linkoption == 'y';
   NEW_3DDOSE = input('Input the full path : ','s');
end

NEW_3DDOSE = [NEW_3DDOSE,'/'];

% Prepare title and strings for internal file identification
MAINtitle=['#MCTP - BEAM link 3ddose files utility. Case study name: ',inputname(1)];
comma=[','];
space=[' '];

% Write link file
linkfilename=[inputname(1),'.createVlinks'];
linkfilenameid=fopen(linkfilename,'w');

if linkfilenameid<0
    error('dicomrt_createVlinks: Error writing script file. Exit now!');
    return
end

if ischar(inputname(2))==1
    temp_newfilename=[Vrtplan];
else
    temp_newfilename=[inputname(2)];
end

time=fix(clock);
fprintf(linkfilenameid,'#!/bin/sh');
fprintf(linkfilenameid,'\n');
fprintf(linkfilenameid,'#****************************************************************************************');
fprintf(linkfilenameid,'\n');
fprintf(linkfilenameid,'#Session started: ');
fprintf(linkfilenameid,date);fprintf(linkfilenameid,'%c',comma);
fprintf(linkfilenameid,'%2i',time(4));
fprintf(linkfilenameid,'%c',':');
fprintf(linkfilenameid,'%2i',time(5));
fprintf(linkfilenameid,'\n');
fprintf(linkfilenameid,MAINtitle);
fprintf(linkfilenameid,'\n');
fprintf(linkfilenameid,'#****************************************************************************************');
fprintf(linkfilenameid,'\n');
fprintf(linkfilenameid,'echo ----------');
fprintf(linkfilenameid,'\n');
for i=1:size(rtplanformc,1) % loop over # beams 
    for j=1:size(rtplanformc{i,3},1)
        origfilename=[inputname(1),'_xyz','_b',int2str(i),'s',int2str(j),'.3ddose'];
        newfilename=[temp_newfilename,'_b',int2str(i),'s',int2str(j),'_mc_xyz_b1s1.3ddose'];
        fprintf(linkfilenameid,'ln -s ');
        fprintf(linkfilenameid,ORIGDIR);
        fprintf(linkfilenameid,origfilename);
        fprintf(linkfilenameid,space);
        fprintf(linkfilenameid,NEW_3DDOSE);
        fprintf(linkfilenameid,newfilename);
        fprintf(linkfilenameid,'\n');
    end
end
fclose(linkfilenameid);


