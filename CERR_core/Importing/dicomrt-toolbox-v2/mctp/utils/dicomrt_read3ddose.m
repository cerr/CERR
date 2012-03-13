function [dose,error,xbound,ybound,zbound] = dicomrt_read3ddose(patient_position,filename)
% dicomrt_read3ddose(patient_position,filename)
%
% Read a BEAM/DOSXYZ .3ddose file.
%
% patient_position is a number which correspond to the supported Patient Position Coordinate System. 
% The egs4phantom will be generated accordingly to the patient position coordinate 
% system and Monte Carlo (DOSXYZ) coordinate system.
%
% Example:
%
% [A,B]=dicomrt_read3ddose(patient_position,'C');
%
% returns in A the 3D dose distribution and in B 3D (relative) error matrix accordingly with Patient Position
% coordinate system.
%
% See also dicomrt_ctcreate, dicomrt_createwphantom, dicomrt_writeegs4phant, dicomrt_loadmcdose
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

fid = fopen(filename,'r');
if fid<0
    disp('3ddose filename ');
    disp(filename);
    error(['dicomrt_read3ddose: 3ddose filename ', filename, ' was not found. Exit now!']);
    return
end

xnum = fscanf(fid,'%i',1);
ynum = fscanf(fid,'%i',1);
znum = fscanf(fid,'%i',1);

xbound = fscanf(fid,'%f',xnum+1);
ybound = fscanf(fid,'%f',ynum+1);
zbound = fscanf(fid,'%f',znum+1);

xbound = dicomrt_mmdigit(xbound,7);
ybound = dicomrt_mmdigit(ybound,7);
zbound = dicomrt_mmdigit(zbound,7);

dose =[];
error=[];

if patient_position == 1
    % 1st case: supported Patient Position is HFS
    for k = 1:znum % load the dose matrix
        dose_temp = fscanf(fid,'%e',[xnum, ynum]);
        dose(:,:,k) = dose_temp';
%        disp(['dose slice ',int2str(k),' loaded'])
    end
    for k = 1:znum % load the error matrix
        error_temp = fscanf(fid,'%e',[xnum, ynum]);
        error(:,:,k) = error_temp';
    end
elseif patient_position == 2
    % 2nd case: supported Patient Position is FFS
    for k = 1:znum % load the dose matrix
        dose_temp = fscanf(fid,'%e',[xnum, ynum]);
        dose(:,:,k) = dose_temp';
%        disp(['dose slice ',int2str(k),' loaded'])
    end
    for k = 1:znum % load the error matrix
        error_temp = fscanf(fid,'%e',[xnum, ynum]);
        error(:,:,k) = error_temp';
    end
elseif patient_position == 3
    % 3rd case: supported Patient Position is HFP
    for k = 1:znum % load the dose matrix
        dose_temp = fscanf(fid,'%e',[xnum, ynum]);
        dose(:,:,k) = dose_temp';
%        disp(['dose slice ',int2str(k),' loaded'])
    end
    for k = 1:znum % load the error matrix
        error_temp = fscanf(fid,'%e',[xnum, ynum]);
        error(:,:,k) = error_temp';
    end
    dose=dicomrt_rotate180y(dose);
    error=dicomrt_rotate180y(error);
    dose=dicomrt_rotate180x(dose);
    error=dicomrt_rotate180x(error);
elseif patient_position == 4
    % 4th case: unsupported Patient Position is FFP
    for k = 1:znum % load the dose matrix
        dose_temp = fscanf(fid,'%e',[xnum, ynum]);
        dose(:,:,k) = dose_temp';
%        disp(['dose slice ',int2str(k),' loaded'])
    end
    for k = 1:znum % load the error matrix
        error_temp = fscanf(fid,'%e',[xnum, ynum]);
        error(:,:,k) = error_temp';
    end
    dose=dicomrt_rotate180y(dose);
    error=dicomrt_rotate180y(error);
    dose=dicomrt_rotate180x(dose);
    error=dicomrt_rotate180x(error);
else
    error('dicomrt_read3ddose: Unable to parse Patient Position. Exit now!');
end
fclose(fid);
