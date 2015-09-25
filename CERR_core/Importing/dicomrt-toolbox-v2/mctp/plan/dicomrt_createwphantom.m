function [ctmediumphantom,ctdensityphantom] = dicomrt_createwphantom(cell_case_study,rtdose_xmesh,rtdose_ymesh,rtdose_zmesh,int)
% dicomrt_createwphantom(cell_case_study,rtdose_xmesh,rtdose_ymesh,rtdose_zmesh,int)
%
% Create a water phantom for BEAM/DOSXYZ simulation
%
% cell_case_study is the radiotherapy plan dataset in the DICOM-RT Toolbox format
% dose_xmesh,dose_ymesh,dose_zmesh are obtained using dicomrt_loaddose
% the water phantom is built using the same matrix of the dose matrix
% user is prompted for filename input
%
% cell_case_study is a simple cell array with the following structure:
%
%  ------------------------
%  | [ rtplan structure ] |
%  | ----------------------
%  | [ 3D dose matrix   ] |
%  | ---------------------
%  | [ voxel dimension  ] |
%  ------------------------
%
% cell_case_study is needed to determine Patient Position to export ctphantom
%
% Int is interactive option. If int ~=1 or if int is not given session is not interactive
% and default parameters (e.g. directories names) will be used. If int = 1 the user will 
% be asked to set some parameters.
%
% See also dicomrt_loaddose, dicomrt_ctcreate
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check number of argument
error(nargchk(4,5,nargin))

if nargin<=4
    int=0;
end

[cell_case_study,type_dose,label,PatientPosition]=dicomrt_checkinput(cell_case_study,1);

% rebuilding mesh matrices
[dose_xmesh,dose_ymesh,dose_zmesh]=dicomrt_rebuildmatrix(rtdose_xmesh,rtdose_ymesh,rtdose_zmesh);

nmat=2;
disp('Generation of a water phantom on a basis of rt plan dose matrix: ');
disp('The following materials will be used: ');
materials = char('AIR521ICRU','H2O521ICRU')
estepe = [0.25;0.25];
ctdensityphantom=ones(size(cell_case_study{2,1}));
ctmediumphantom=ones(size(cell_case_study{2,1}));
ctmediumphantom(:,:,:)=2; 

% Export to file. 
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
        xthick=abs(dose_xmesh(1,1,1)-dose_xmesh(1,2,1));
        ythick=abs(dose_ymesh(1,1,1)-dose_ymesh(2,1,1));
        zthick=abs(dose_zmesh(1,1,1)-dose_zmesh(1,1,2));
        
        % boundaries -1
        x_bound=(dose_xmesh(1,:,1)-xthick/2)';
        y_bound=dose_ymesh(:,1,1)-ythick/2;
        z_bound=(dose_zmesh(1,1,:)-zthick/2);
        z_bound_vect=[];
        for i=1:size(z_bound,3);
            z_bound_vect(i)=z_bound(1,1,i);
        end
        z_bound_vect=z_bound_vect';
        
        % boundaries
        x_bound=[x_bound;x_bound(size(x_bound,1))+xthick];
        y_bound=[y_bound;y_bound(size(y_bound,1))+ythick];
        z_bound_vect=[z_bound_vect;z_bound_vect(size(z_bound_vect,1))+zthick];
        
        filename = input('Input the egs4phant filename (no ext): ','s'); % Name of the file where to store ctphantom
        
        if filename == 'N' | filename == 'n';
            warning('dicomrt_createwphantom: No filename was input. Filename "filename" will be used');
            filename=['filename.egs4phant'];
            dicomrt_writeegs4phant(PatientPosition,nmat,materials,estepe,size(dose_xmesh,2),size(dose_xmesh,1), ...
                size(dose_xmesh,3),x_bound,y_bound,z_bound_vect, ...
                ctmediumphantom,ctdensityphantom,filename);
        else
            filename=[filename,'.egs4phant'];
            dicomrt_writeegs4phant(PatientPosition,nmat,materials,estepe,size(dose_xmesh,2),size(dose_xmesh,1), ...
                size(dose_xmesh,3),x_bound,y_bound,z_bound_vect, ...
                ctmediumphantom,ctdensityphantom,filename);
        end
    else
        disp('No export will be performed. Data will be stored on disk');
        save 
    end
else
     
    % Prepare to export
    % pixel spacing
    xthick=abs(dose_xmesh(1,1,1)-dose_xmesh(1,2,1));
    ythick=abs(dose_ymesh(1,1,1)-dose_ymesh(2,1,1));
    zthick=abs(dose_zmesh(1,1,1)-dose_zmesh(1,1,2));
    
    % boundaries -1
    x_bound=(dose_xmesh(1,:,1)-xthick/2)';
    y_bound=dose_ymesh(:,1,1)-ythick/2;
    z_bound=(dose_zmesh(1,1,:)-zthick/2);
    z_bound_vect=[];
    for i=1:size(z_bound,3);
       z_bound_vect(i)=z_bound(1,1,i);
    end
    z_bound_vect=z_bound_vect';
    
    % boundaries
    x_bound=[x_bound;x_bound(size(x_bound,1))+xthick];
    y_bound=[y_bound;y_bound(size(y_bound,1))+ythick];
    z_bound_vect=[z_bound_vect;z_bound_vect(size(z_bound_vect,1))+zthick];
    
    filename=inputname(1)
    filename=[filename,'.egs4phant'];
    
    dicomrt_writeegs4phant(PatientPosition,nmat,materials,estepe,size(dose_xmesh,2),size(dose_xmesh,1), ...
        size(dose_xmesh,3),x_bound,y_bound,z_bound_vect, ...
        ctmediumphantom,ctdensityphantom,filename);
end
