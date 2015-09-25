function dicomrt_write3ddose(dose,error,dose_xmesh,dose_ymesh,dose_zmesh,filename)
% dicomrt_write3ddose(dose,error,dose_xmesh,dose_ymesh,dose_zmesh,filename)
%
% Write 3D dose and error into a BEAM/DOSXYZ .3ddose file 

% filename is the name of the file (no extension) to write
% dose contains the 3D dose distribution
% error contains the relative error
% dose_xmesh, dose_ymesh and dose_zmesh are the boundaries of the dose voxels as read from rtplan
%
% Example:
%
% dicomrt_write3ddose(A,B,xmesh,ymesh,zmesh,'test.3ddose');
%
% write 3D dose A and 3D relative error B in .
%
% See also dicomrt_ctcreate, dicomrt_writeegs4phant, dicomrt_loadmcdose, dicomrt_loaddose
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

filename=[filename,'.3ddose'];

% Check filename
fid = fopen(filename,'w')
if fid<0
    error('dicomrt_write3ddose: Unable to open 3ddose filename ') 
end

% Define parameters
space=[' '];
%xnum=length(dose_xmesh,2);
%ynum=length(dose_ymesh,1);
%znum=length(dose_zmesh,1);

xnum=length(dose_xmesh);
ynum=length(dose_ymesh);
znum=length(dose_zmesh);

pixel_spacing_x=dose_xmesh(2)-dose_xmesh(1);
min_x=min(dose_xmesh)-pixel_spacing_x/2;
max_x=max(dose_xmesh)+pixel_spacing_x/2;

pixel_spacing_y=dose_ymesh(2)-dose_ymesh(1);
min_y=min(dose_ymesh)-pixel_spacing_y/2;
max_y=max(dose_ymesh)+pixel_spacing_y/2;

pixel_spacing_z=dose_zmesh(2)-dose_zmesh(1);
slice_thickness=abs(dose_zmesh(2)-dose_zmesh(1));
min_z=min(dose_zmesh)-slice_thickness/2;
max_z=max(dose_zmesh)+slice_thickness/2;

dose_xmesh=[min_x:pixel_spacing_x:max_x];
dose_ymesh=[min_y:pixel_spacing_y:max_y];
dose_zmesh=[min_z:slice_thickness:max_z];

xbound=dose_xmesh;
ybound=dose_ymesh;
zbound=dose_zmesh;

% Write data
fprintf(fid,'%4i',xnum);fprintf(fid,space);
fprintf(fid,'%4i',ynum);fprintf(fid,space);
fprintf(fid,'%4i',znum);fprintf(fid,space);
fprintf(fid,'\n');

for i=1:xnum+1
    fprintf(fid,'%12.8f %c',xbound(i),space);
end
fprintf(fid,'\n');

for i=1:ynum+1
    fprintf(fid,'%12.8f %c',ybound(i),space);
end
fprintf(fid,'\n');

for i=1:znum+1
    fprintf(fid,'%12.8f %c',zbound(i),space);
end

% write the dose and the error matrix

for k=1:znum
    fprintf(fid,'\n');
    for j=1:ynum
        fprintf(fid,'\n');
        for i=1:xnum
            fprintf(fid,'%10.8e %c',dose(j,i,k));
        end
   end
end

for k=1:znum
    fprintf(fid,'\n');
    for j=1:ynum
        fprintf(fid,'\n');
        for i=1:xnum
            fprintf(fid,'%12.10f %c',error(j,i,k));
        end
   end
end

fclose(fid);
