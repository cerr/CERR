function [media,density,medname,xbound,ybound,zbound] = dicomrt_readegs4phant(patient_position,filename)
% dicomrt_readegs4phant(patient_position,filename)
%
% Read a ct phantom which comply to BEAM/DOSXYZ file format
% Return media matrix and density matrix.
%
% patient_position is a code which correspond to one of the supported
% patient position cases
% Filename is an character string which contain the name of the egs4phantom file (no extension).
%
% Example:
%
% [A,B,medname]=dicomrt_readegs4phant(1,'demo')
%
% will store in A the medium number and in B the density read from the egs4phantom demo.egs4phant;
% Materials name are stored in medname. This information is required when converting 
% dose2medium <-> dose2water.
%
% See also dicomrt_ctcreate, dicomrt_getPatientPosition
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

filename=[filename,'.egs4phant'];
fid=fopen(filename);
nummedia = fscanf(fid,'%i');
medname=cell(nummedia,1);

for i=1:nummedia
    medname{i,1}=fgetl(fid);
end

for i=1:nummedia
    estepe(i,:) = fscanf(fid,'%f',1);
end

global xnum;
global ynum;
global znum;

xnum = fscanf(fid,'%i',1);
ynum = fscanf(fid,'%i',1);
znum = fscanf(fid,'%i',1);

xbound = fscanf(fid,'%f',xnum+1);
ybound = fscanf(fid,'%f',ynum+1);
zbound = fscanf(fid,'%f',znum+1);

xbound = dicomrt_mmdigit(xbound,7,10,'fix');
ybound = dicomrt_mmdigit(ybound,7,10,'fix');
zbound = dicomrt_mmdigit(zbound,7,10,'fix');

if patient_position == 1
    % 1st case: supported Patient Position is HFS
    %load the media matrix
    media=[];
    for k=1:znum
        media_temp = fscanf(fid,'%1i',[xnum, ynum]);
        media(:,:,k) = media_temp';
        line = fgets(fid);
    end
    % load the density matrix
    for k = 1:znum 
        density_temp = fscanf(fid,'%f',[xnum, ynum]);
        density(:,:,k) = density_temp';
    end
elseif patient_position == 2
    % 2nd case: supported Patient Position is FFS 
    %load the media matrix
    media=[];
    for k=1:znum
        media_temp = fscanf(fid,'%1i',[xnum, ynum]);
        media(:,:,k) = media_temp';
        line = fgets(fid);
    end
    % load the density matrix
    for k = 1:znum 
        density_temp = fscanf(fid,'%f',[xnum, ynum]);
        density(:,:,k) = density_temp';
    end
end
fclose(fid);