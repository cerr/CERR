function dicomrt_createmclinks = dicomrt_createmclinks(study,beam_module,int)
% dicomrt_createmclinks(study,beam_module,int)
%
% Create links from original MC phase space file directory to a user specified directory
% this is to avoid PHSPFILENAME being longer than 80 character supported by BEAM/DOSXYZ
%
% rtplanform contains plan data coded (warmed) by dicomrt_mcwarm.
% beam_module is the MC model to use
% int is a parameter which determines an interactive session (int~=0). During interactive session 
%     it is possible to specify the name of directories where files will be linked. (OPTIONAL)
%
% Example:
%
% dicomrt_createmclinks(A,'BEAM_Clinac21CD')
%
% will create:
%
% A.createlinks     when executed links phsp files from original BEAM 'BEAM_Clinac21CD' dir 
%                   to user defined dir this may be useful when path to original BEAM dir  
%                   is too long to fit in the BEAM/DOSXYZ supported 80 characters
%
%
% See also dicomrt_mcwarm, dicomrt_BEAMexport, dicomrt_DOSXYZexport, dicomrt_createmcscripts
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org)

% Check number of argument
error(nargchk(2,3,nargin))

% Check input
[study,type]=dicomrt_checkinput(study);
if isequal(type,'RTPLAN')==1
    rtplanformc=dicomrt_mcwarm(study);
else
    error('dicomrt_createmcscripts: invalid input data format');
end

if exist('int')==0
    int=0;
end

% Default directories
LOCAL_EGS=['/user/phexternal/phx1pl/cardiff/egs4'];
PHSPFILEDIR=['/user/phexternal/phx1pl/cardiff'];

% Almost ready to write link file: ask some question if session is interactive
if int~=0
    disp(' ');
    disp('Current default for local egs4 directory is: ');
    disp(LOCAL_EGS);
    egs4option = input('Do you want to change this default path Y/N [N]:','s');
    if egs4option == 'Y' | egs4option == 'y';
        LOCAL_EGS = input('Input the filename complete of full path : ','s');
    end

    % PHSPFILEDIR is the directory where phsp files are suppose to be linked 
    % this is to avoid PHSPFILENAME being longer than 80 character supported by BEAM/DOSXYZ
    disp(' ');
    disp('Current directory where phsp files will be linked is: ');
    disp(PHSPFILEDIR);
    linkoption = input('Do you want to change this default path Y/N [N]:','s');
    if linkoption == 'Y' | linkoption == 'y';
        PHSPFILEDIR = input('Input the full path : ','s');
    end
end

ORIGDIR=[LOCAL_EGS,'/',beam_module,'/'];
PHSPFILEDIR = [PHSPFILEDIR,'/'];

% Prepare title and strings for internal file identification
MAINtitle=['#MCTP - BEAM link phsp files utility. Case study name: ',inputname(1)];
comma=[','];
space=[' '];

% Write link file
linkfilename=[inputname(1),'.createlinks'];
linkfilenameid=fopen(linkfilename,'w');

if linkfilenameid<0
    error('dicomrt_createmclinks: Error writing script file. Exit now!');
    return
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
        filename=[inputname(1),'_b',int2str(i),'s',int2str(j),'.egs4phsp1'];
        fprintf(linkfilenameid,'ln -s ');
        fprintf(linkfilenameid,ORIGDIR);
        fprintf(linkfilenameid,filename);
        fprintf(linkfilenameid,space);
        fprintf(linkfilenameid,PHSPFILEDIR);
        fprintf(linkfilenameid,filename);
        fprintf(linkfilenameid,'\n');
    end
end
fclose(linkfilenameid);


