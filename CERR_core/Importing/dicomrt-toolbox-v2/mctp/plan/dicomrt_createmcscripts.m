function dicomrt_createmcscripts = dicomrt_createmcscripts(study,mcmodule,hostlist)
% dicomrt_createmcscripts(study,mcmodule,hostlist)
%
% Create scripts for automatic launch of MC simulation on "hostlist"
%
% Example:
%
% dicomrt_createmcscripts(A,dosxyz,beowulf)
%
% will create:
%
% if mcmodule~=dosxyz
%
% A_b?.launch       when executed launch BEAM MC simulation for segments of beam "?"
%                   using BEAM module "mcmodule"
%
% if mcmodule=dosxyz
%
% A_xyz_b?.launch   when executed launch DOSXYZ MC simulation for segments of beam "?"
%
% Simulations will be submitted to remote hosts specified in beowulf.
% File beowulf must contain a valid list of remote hosts in the following format
% 
% host1
% host2
%  ...
% hostn
% 
% NOTE1: beowulf filename must be a character string
% NOTE2: if # of segments exeed # of hosts exeeding simulations will be submitted 
%        restarting from first remote host in the list
%
% See also dicomrt_BEAMexport, dicomrt_DOSXYZexport
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org)

% Check hostlist: it cannot be a variable
if ischar(hostlist)~=1, error('dicomrt_createmcscripts: Host filename must be a character string. Exit now!'); end

% Check input
[study,type]=dicomrt_checkinput(study);
if isequal(type,'RTPLAN')==1
    rtplanformc=dicomrt_mcwarm(study);
else
    error('dicomrt_createmcscripts: invalid input data format');
end

if fopen(hostlist)<0
    error('dicomrt_createmcscripts: Host filename not found. Exit now!');
    return
end

% Open hostlist and get hosts' # hosts' name
hostlistid=fopen(hostlist);
nhost=0;
while (feof(hostlistid)~=1);
    nhost=nhost+1;     % counting
    nhostcheck=nhost;  % check for eof
    hostname{nhost,1}=fgetl(hostlistid);
    if isnumeric(hostname{nhost,1}), nhost=nhost-1, break, end %end of line reached
end
fclose(hostlistid);

% Prepare title and strings for internal file identification
MAINtitle=['#MCTP - BEAM-DOSXYZ launch file. Case study name: ',inputname(1)];
comma=[','];
space=[' '];
xyz_pegs=['521icru'];
beam_pegs=['521icru'];

% Get total number of segments for this plan
totalsegments=0;
for i=1:size(rtplanformc,1) % loop over # beams
    totalsegments=totalsegments+size(rtplanformc{i,3},1);
end

% Define local variable and counter
simtosend=cell(totalsegments,2);
k=0;

% Associate simulation to host through simtosend

available_modules=char('dosxyz',mcmodule);

if available_modules(2,:)==available_modules(1,:);   
    for i=1:size(rtplanformc,1)
        for j=1:size(rtplanformc{i,3},1)
            k=k+1;
            simtosend{k,1}=[inputname(1),'_xyz_b',int2str(i),'s',int2str(j)];
        end
    end
else
    for i=1:size(rtplanformc,1)
        for j=1:size(rtplanformc{i,3},1)
            k=k+1;
            simtosend{k,1}=[inputname(1),'_b',int2str(i),'s',int2str(j)];
        end
    end
end

for i=1:totalsegments
    host=rem(i,nhost);
    if host~=0;
        simtosend{i,2}=hostname{host,1};
    else
        simtosend{i,2}=hostname{nhost,1};
    end
end % Association completed

% Write launch files
if available_modules(2,:)~=available_modules(1,:);
    k=0;
    for i=1:size(rtplanformc,1) % loop over # beams 
        launchbeamname=[inputname(1),'_b',int2str(i),'.launch'];
        launchbeamid=fopen(launchbeamname,'w');
        time=fix(clock);
        fprintf(launchbeamid,'#!/bin/sh');
        fprintf(launchbeamid,'\n');
        fprintf(launchbeamid,'#****************************************************************************************');
        fprintf(launchbeamid,'\n');
        fprintf(launchbeamid,'#Session started: ');
        fprintf(launchbeamid,date);fprintf(launchbeamid,'%c',comma);
        fprintf(launchbeamid,'%2i',time(4));
        fprintf(launchbeamid,'%c',':');
        fprintf(launchbeamid,'%2i',time(5));
        fprintf(launchbeamid,'\n');
        fprintf(launchbeamid,MAINtitle);
        fprintf(launchbeamid,'\n');
        fprintf(launchbeamid,'#****************************************************************************************');
        fprintf(launchbeamid,'\n');
        fprintf(launchbeamid,'echo ----------');
        fprintf(launchbeamid,'\n');
        for j=1:size(rtplanformc{i,3},1) % loop over segments
            fprintf(launchbeamid,'echo Sending job to host: ');
            fprintf(launchbeamid,simtosend{j+k,2});
            fprintf(launchbeamid,'\n');
            fprintf(launchbeamid,'rsh ');
            fprintf(launchbeamid,simtosend{j+k,2});
            fprintf(launchbeamid,' $HEN_HOUSE/egs4_batch_run ');
            fprintf(launchbeamid,mcmodule);
            fprintf(launchbeamid,space);
            fprintf(launchbeamid,simtosend{j+k,1});
            fprintf(launchbeamid,space);
            fprintf(launchbeamid,beam_pegs);
            fprintf(launchbeamid,'\n');
            fprintf(launchbeamid,'echo job submitted.');
            fprintf(launchbeamid,'\n');
            fprintf(launchbeamid,'sleep 5');
            fprintf(launchbeamid,'\n');
        end
        k=k+size(rtplanformc{i,3},1);
        fclose(launchbeamid);
    end   
else
    k=0;
    for i=1:size(rtplanformc,1) % loop over # beams 
        launchbeamname=[inputname(1),'_xyz_b',int2str(i),'.launch'];
        launchbeamid=fopen(launchbeamname,'w');
        time=fix(clock);
        fprintf(launchbeamid,'#!/bin/sh');
        fprintf(launchbeamid,'\n');
        fprintf(launchbeamid,'#****************************************************************************************');
        fprintf(launchbeamid,'\n');
        fprintf(launchbeamid,'#Session started: ');
        fprintf(launchbeamid,date);fprintf(launchbeamid,'%c',comma);
        fprintf(launchbeamid,'%2i',time(4));
        fprintf(launchbeamid,'%c',':');
        fprintf(launchbeamid,'%2i',time(5));
        fprintf(launchbeamid,'\n');
        fprintf(launchbeamid,MAINtitle);
        fprintf(launchbeamid,'\n');
        fprintf(launchbeamid,'#****************************************************************************************');
        fprintf(launchbeamid,'\n');
        fprintf(launchbeamid,'echo ----------');
        fprintf(launchbeamid,'\n');
        for j=1:size(rtplanformc{i,3},1) % loop over segments
            fprintf(launchbeamid,'echo Sending job to host: ');
            fprintf(launchbeamid,simtosend{j+k,2});
            fprintf(launchbeamid,'\n');
            fprintf(launchbeamid,'rsh ');
            fprintf(launchbeamid,simtosend{j+k,2});
            fprintf(launchbeamid,' $HEN_HOUSE/egs4_batch_run ');
            fprintf(launchbeamid,mcmodule);
            fprintf(launchbeamid,space);
            fprintf(launchbeamid,simtosend{j+k,1});
            fprintf(launchbeamid,space);
            fprintf(launchbeamid,xyz_pegs);
            fprintf(launchbeamid,'\n');
            fprintf(launchbeamid,'echo job submitted.');
            fprintf(launchbeamid,'\n');
            fprintf(launchbeamid,'sleep 5');
            fprintf(launchbeamid,'\n');
        end
        k=k+size(rtplanformc{i,3},1);
        fclose(launchbeamid);
    end
end % launch files written

