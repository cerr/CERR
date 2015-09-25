function [ctmediumphantom,ctdensityphantom] = dicomrt_ctcreate(inpct_matrix,ct_xmesh,ct_ymesh,ct_zmesh,rtdose_xmesh,rtdose_ymesh,rtdose_zmesh,plotramp,int)
% dicomrt_ctcreate(inpct_matrix,ct_xmesh,ct_ymesh,ct_zmesh,rtdose_xmesh,rtdose_ymesh,rtdose_zmesh,plotramp,int)
%
% Create a ct phantom for BEAM/DOSXYZ simulation. Light Version.
%
% inpct_matrix is the CT dataset
% ct_xmesh, ct_ymesh, ct_zmesh are the coordinates of the voxels for the CT dataset
% rtdose_xmesh, rtdose_ymesh, rtdose_zmesh are the coordinates of the voxels
% of the 3D dose distribution
% plotramp is an option for plotting the CT ramp (~=0 plot, =0[default] no plot)
% Int is a parameter for interactive session. 
%     If int ~=1 or if int is not given session is not interactive
%     and default parameters (e.g. directories names) will be used. If int = 1 the user will 
%     be asked to set some parameters.
%
% Parameters for this specific m file are:
%
% nmat				    number of material
% materials			    materials name
% medium				materials number
% mat_ct_up_bound		materials upper bound (see dosxyz user's manual)
% density_lo_bound		density lower bound (see dosxyz user's manual)
% density_up_bound		density upper bound (see dosxyz user's manual)
% estepe				estepe (see dosxyz user's manual)
% filename			    ct phantom filename for export
%
% See also dicomrt_loaddose, dicomrt_rotate180x
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check number of argument
error(nargchk(8,9,nargin))

if nargin<=8
    int=0;
end

% Check case and set-up some parameters and variables
[ct_matrix_temp,type_dose,label,PatientPosition]=dicomrt_checkinput(inpct_matrix);
ct_matrix=dicomrt_varfilter(ct_matrix_temp);

[ct_xmesh_2d,ct_ymesh_2d]=dicomrt_build2dgrid(ct_xmesh,ct_ymesh);
[dose_xmesh_2d,dose_ymesh_2d]=dicomrt_build2dgrid(rtdose_xmesh,rtdose_ymesh);

% 1a) resize ct_matrix using dose_xmesh, dose_ymesh, dose_zmesh
% loop over dose_zmesh size since the rt plan could have been performed on a subset of the original ct images
for i=1:length(rtdose_zmesh)
    if i==1 % locate z position of the first slice to start with
      first_zlocation=rtdose_zmesh(i);
      for k=1:length(ct_zmesh)
         temp=num2str(ct_zmesh(k));
         array=char(temp,num2str(first_zlocation));
         if array(1,:)==array(2,:);
            break
         end
      end
      zstart=k; % match with dose matrix
   end
   ctphantom(:,:,i)=interp2(ct_xmesh_2d,ct_ymesh_2d,ct_matrix(:,:,k+i-1), ...
       dose_xmesh_2d,dose_ymesh_2d,'nearest');
end

% 1b) Cut off negative values form outside CT FOV
ctphantom(find((ctphantom)<=0))=10; % a CT value for air

% 2a) Retrieve ctphantom parameters: if int==1 start interactive session
if isnumeric(int)==1 &  int==1
    nmat = input('Input the number of materials [Enter for default]: '); % Number of material
    if isempty(nmat)==1
        nmat=4;
        %disp('The following materials will be used: ');
        materials          = char('AIR521ICRU','LUNG521ICRU','ICRUTISSUE521ICRU','ICRPBONE521ICRU');
        medium             = [1;     2;     3;     4];
        mat_ct_up_bound    = [50;    300;   1125;  5000];
        density_lo_bound   = [0.001; 0.044; 0.302; 1.101];
        density_up_bound   = [0.044; 0.302; 1.101; 3.48];
        estepe             = [0.25;  0.25;  0.25;  0.25];
    else
        medium = [1:nmat]';
        for i=1:nmat
            mat = input('Input the name of material: ','s'); % Name of material
            if i==1
                materials = mat;
            else
                materials = char(materials,mat);
            end
            mat_ct_up_bound(i) = input('Input the material ct upper bound: ');
            density_lo_bound(i) = input('Input the density ct lower bound: ');
            density_up_bound(i) = input('Input the density ct upper bound: ');
            estepe(i) = input('Input estepe for this material: ');
        end
        estepe=estepe';
    end % ctphantom parameters retrieved  
else
    nmat=4;
    %disp('The following materials will be used: ');
    materials          = char('AIR521ICRU','LUNG521ICRU','ICRUTISSUE521ICRU','ICRPBONE521ICRU');
    medium             = [1;     2;     3;     4];
    mat_ct_up_bound    = [50;    300;   1125;  5000];
    density_lo_bound   = [0.001; 0.044; 0.302; 1.101];
    density_up_bound   = [0.044; 0.302; 1.101; 3.84];
    estepe             = [0.25;  0.25;  0.25;  0.25];
end

% 2b) Plot CT ramp
if plotramp~=0
    disp('Plotting CT conversion ramp being used: ');
    dicomrt_plotctramp(inputname(1),materials,mat_ct_up_bound,density_lo_bound,density_up_bound);
end

% 3) Build ctphantom

% 3a) CT to medium
ctmediumphantom=ctphantom;
for i=1:nmat
    if i==1
        ctmediumphantom(find((ctmediumphantom<=mat_ct_up_bound(i) & ...
            ctmediumphantom>0)))=medium(i);
    else
        ctmediumphantom(find((ctmediumphantom<=mat_ct_up_bound(i) & ...
            ctmediumphantom>mat_ct_up_bound(i-1))))=medium(i);
    end
end

% 3b) Convert CT data to density
ctdensityphantom=ones(size(ctmediumphantom,1),size(ctmediumphantom,2),size(ctmediumphantom,3));
for i=1:nmat
    if i==1
        a=density_lo_bound(i);
        b=density_up_bound(i)-density_lo_bound(i);
        c=mat_ct_up_bound(i);
        d=ctphantom(find((ctmediumphantom==medium(i))));
        ctdensityphantom(find((ctmediumphantom==medium(i)))) = a+(b/c)*d;
    else
        a=density_lo_bound(i);
        b=density_up_bound(i)-density_lo_bound(i);
        c=mat_ct_up_bound(i)-mat_ct_up_bound(i-1);
        d=ctphantom(find((ctmediumphantom==medium(i))))-mat_ct_up_bound(i-1);
        ctdensityphantom(find((ctmediumphantom==medium(i)))) = a+(b/c)*d;
    end
end

% 5) Export to file. 
%
% ImagePositionPatient is the (x,y,z) coordinate of the first pixel (mm).
% Therefore the mesh produced so far represent the coordinates of the center of the voxels.
% CTphantom need the coordinates of the boundaries of the voxels.
%
if isnumeric(int)==1 &  int==1
    export = input('Do you want to export the ctphantom ? Y/N [N]: ','s');
    if export == 'Y' | export == 'y';
        % Prepare to export
        % pixel spacing
        xthick=abs(rtdose_xmesh(1)-rtdose_xmesh(2));
        ythick=abs(rtdose_ymesh(1)-rtdose_ymesh(2));
        zthick=abs(rtdose_zmesh(1)-rtdose_zmesh(2));
        
        x_bound=dicomrt_createboundgrid(rtdose_xmesh);
        y_bound=dicomrt_createboundgrid(rtdose_ymesh);
        z_bound=dicomrt_createboundgrid(rtdose_zmesh);
                
        filename = input('Input the egs4phant filename (no ext): ','s'); % Name of the file where to store ctphantom
        
        if filename == 'N' | filename == 'n';
            warning('dicomrt_ctcreate: No filename was input. Filename "filename" will be used');
            filename=['filename.egs4phant'];
            dicomrt_writeegs4phant(PatientPosition,nmat,materials,estepe,length(rtdose_xmesh),length(rtdose_ymesh), ...
                length(rtdose_zmesh),x_bound,y_bound,z_bound,ctmediumphantom,ctdensityphantom,filename);
        else
            filename=[filename,'.egs4phant'];
            dicomrt_writeegs4phant(PatientPosition,nmat,materials,estepe,length(rtdose_xmesh),length(rtdose_ymesh), ...
                length(rtdose_zmesh),x_bound,y_bound,z_bound,ctmediumphantom,ctdensityphantom,filename);
        end
    else
        disp('No export will be performed. Data will be stored on disk');
        save 
    end
else
    % Prepare to export
    % pixel spacing
    xthick=abs(rtdose_xmesh(1)-rtdose_xmesh(2));
    ythick=abs(rtdose_ymesh(1)-rtdose_ymesh(2));
    zthick=abs(rtdose_zmesh(1)-rtdose_zmesh(2));
    
    x_bound=dicomrt_createboundgrid(rtdose_xmesh);
    y_bound=dicomrt_createboundgrid(rtdose_ymesh);
    z_bound=dicomrt_createboundgrid(rtdose_zmesh);
    
    filename=inputname(1);
    filename=[filename,'.egs4phant'];
    
    dicomrt_writeegs4phant(PatientPosition,nmat,materials,estepe,length(rtdose_xmesh),length(rtdose_ymesh), ...
        length(rtdose_zmesh),x_bound,y_bound,z_bound,ctmediumphantom,ctdensityphantom,filename);
end
