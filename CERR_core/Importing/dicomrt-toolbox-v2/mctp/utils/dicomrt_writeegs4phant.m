function [media, density] = dicomrt_writeegs4phant(patient_position,nummedia,medname,estepe,xnum,ynum,znum,xbound,ybound,zbound,media,density,filename)
% dicomrt_writeegs4phant(patient_position,nummedia,medname,estepe,xnum,ynum,znum,xbound,ybound,zbound,media,density,filename)
%
% Write an egs4 phantom file which conforms to the NRC BEAM standard format.
%
% patient_position is a number which correspond to the supported Patient Position Coordinate System. 
% The egs4phantom will be generated accordingly to the patient position coordinate 
% system and Monte Carlo (DOSXYZ) coordinate system.
%
% Example:
%
% [A,B]=dicomrt_writeegs4phant(patient_position,nummedia,medname,estepe,xnum,ynum,znum,xbound,ybound,zbound,media,density,filename)
% returns in A the media phantom and in B the density phantom and write the egs4phantom in the file "filename".
%
% See also dicomrt_ctcreate, dicomrt_createwphantom, dicomrt_getPatientPosition
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% 1) Adjust matrices accordingly with Patient Position Coordinate System
if patient_position == 1 % supported Patient Position: HFS
    % rotate ctmediumphantom and ctdensityphantom
    [media]=dicomrt_rotate180x(media);
    [density]=dicomrt_rotate180x(density);
elseif patient_position == 2 %  supported Patient Position: FFS
    [media]=dicomrt_rotate180x(media);
    [density]=dicomrt_rotate180x(density);
elseif patient_position == 3 %  supported Patient Position: HFP
    [media]=dicomrt_rotate180y(media);
    [density]=dicomrt_rotate180y(density);
elseif patient_position == 4 %  supported Patient Position: FFP
    [media]=dicomrt_rotate180y(media);
    [density]=dicomrt_rotate180y(density);
end

% 2) write boundaries information
fid = fopen(filename,'w');
fprintf(fid,'%2i',nummedia);
fprintf(fid,'\n');

for i=1:nummedia
fprintf(fid,'%c',medname(i,:));
fprintf(fid,'\n');
end

for i=1:nummedia
fprintf(fid,'%6.2f',estepe(i,:));
end
fprintf(fid,'\n');

fprintf(fid,'%5i',xnum,ynum,znum);
fprintf(fid,'\n');

if patient_position == 1 | patient_position == 2
    fprintf(fid,'%12.8f %12.8f %12.8f %12.8f %12.8f %12.8f\n',xbound);
    fprintf(fid,'\n');
    
    fprintf(fid,'%12.8f %12.8f %12.8f %12.8f %12.8f %12.8f\n',ybound);
    fprintf(fid,'\n'); 
    
    fprintf(fid,'%12.8f %12.8f %12.8f %12.8f %12.8f %12.8f\n',zbound);
    fprintf(fid,'\n');
else
    fprintf(fid,'%12.8f %12.8f %12.8f %12.8f %12.8f %12.8f\n',flipdim(xbound,1));
    fprintf(fid,'\n');
    
    fprintf(fid,'%12.8f %12.8f %12.8f %12.8f %12.8f %12.8f\n',flipdim(ybound,1));
    fprintf(fid,'\n'); 
    
    fprintf(fid,'%12.8f %12.8f %12.8f %12.8f %12.8f %12.8f\n',zbound);
    fprintf(fid,'\n');
end

% 3) write CT slices as coded by ctcreate

if patient_position == 1 
    % 1st case: supported Patient Position is HFS
    % ctmediumphantom and ctdensityphantom were rotated earlier of
    % 180 degrees about X axis. Therefore matrices must to be written
    % starting from highest z number which correspond to lower Z coordinate
    % 3a) write densities of each voxel for each slice
    for k = znum:-1:1
        temp = media(:,:,k);
        for j = ynum:-1:1 % start writing from the lowest Y coordinate
            fprintf(fid,'%i',temp(j,:));
            fprintf(fid,'\n'); 
        end
        fprintf(fid,'\n');
    end
    % 3b) write densities of each voxel for each slice
    for k = znum:-1:1
        for j = ynum:-1:1;
            fprintf(fid,'%13.10f %13.10f %13.10f %13.10f %13.10f\n',density(j,:,k));
            fprintf(fid,'\n');
        end
        fprintf(fid,'\n');
    end
    fclose(fid);
elseif patient_position == 2
    % 2nd case: supported Patient Position is FFS 
    % ctmediumphantom and ctdensityphantom were rotated earlier of
    % 180 degrees about X axis. Therefore matrices must to be written
    % starting from highest z number which correspond to lower Z coordinate
    % 3a) write densities of each voxel for each slice
    for k = znum:-1:1
        temp = media(:,:,k);
        for j = ynum:-1:1 % start writing from the lowest Y coordinate
            fprintf(fid,'%i',temp(j,:));
            fprintf(fid,'\n'); 
        end
        fprintf(fid,'\n');
    end
    % 3b) write densities of each voxel for each slice
    for k = znum:-1:1
        for j = ynum:-1:1;
            fprintf(fid,'%13.10f %13.10f %13.10f %13.10f %13.10f\n',density(j,:,k));
            fprintf(fid,'\n');
        end
        fprintf(fid,'\n');
    end
    fclose(fid);
elseif patient_position == 3
    % 3rd case: supported Patient Position is HFP 
    % ctmediumphantom and ctdensityphantom were rotated earlier of
    % 180 degrees about Y axis. Therefore matrices must to be written
    % starting from highest z number which correspond to lower Z coordinate
    % 3a) write densities of each voxel for each slice
    for k = znum:-1:1
        temp = media(:,:,k);
        for j = ynum:-1:1 % start writing from the lowest Y coordinate
            %fprintf(fid,'%i',flipdim(temp(j,:),2));
            fprintf(fid,'%i',temp(j,:));
            fprintf(fid,'\n'); 
        end
        fprintf(fid,'\n');
    end
    % 3b) write densities of each voxel for each slice
    for k = znum:-1:1
        for j = ynum:-1:1;
            %fprintf(fid,'%13.10f %13.10f %13.10f %13.10f %13.10f\n',flipdim(squeeze(density(j,:,k)),2));
            fprintf(fid,'%13.10f %13.10f %13.10f %13.10f %13.10f\n',density(j,:,k));
            fprintf(fid,'\n');
        end
        fprintf(fid,'\n');
    end
    fclose(fid);
elseif patient_position == 4
    % 4th case: unsupported Patient Position is FFP 
    % Matrices must to be written starting from highest z number 
    % which correspond to lower Z coordinate
    % 3a) write densities of each voxel for each slice
    for k = znum:-1:1
        temp = media(:,:,k);
        for j = ynum:-1:1 % start writing from the lowest Y coordinate
            %fprintf(fid,'%i',flipdim(temp(j,:),2)); 
            fprintf(fid,'%i',temp(j,:)); 
            fprintf(fid,'\n'); 
        end
        fprintf(fid,'\n');
    end
    % 3b) write densities of each voxel for each slice
    for k = znum:-1:1
        for j = ynum:-1:1;
            %fprintf(fid,'%13.10f %13.10f %13.10f %13.10f %13.10f\n',flipdim(squeeze(density(j,:,k)),2));
            fprintf(fid,'%13.10f %13.10f %13.10f %13.10f %13.10f\n',density(j,:,k));
            fprintf(fid,'\n');
        end
        fprintf(fid,'\n');
    end
    fclose(fid);
end