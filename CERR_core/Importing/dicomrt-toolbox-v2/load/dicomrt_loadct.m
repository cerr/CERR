function [ctcell,ct_xmesh,ct_ymesh,ct_zmesh] = dicomrt_loadct(filename,sorting)
% dicomrt_loadct(filename,sorting)
%
% Read dicom CT for a case using MATLAB native function dicomread. Light Version.
%
% filename contains a list of CT slices to import
%
% CT are stored in a single 3D matrix: case_study
% x-y-z coordinates of the center of the ct-pixel are stored in ct_xmesh, ct_ymesh and ct_zmesh.
%
% NOTE:  CT numbers range from -1000 for air to 1000 for bone with that for water set to 0.
% CT numbers normalized in this manner are called Hounfield numbers or units (HU):
%
% HU = ((mu_tissue-mu_water)/mu_water)*1000
%
% Following DICOM RT standard HU = m*(SV)+b where m is RescaleSlope, b RescaleIntercept
% and SV are pixel (stored) values.
%
% Often CT scale is shifted so that HU(water)=1000 (=CToffset) instead of 0.
%
% NOTE: as opposed to dicomrt_loadct ct_xmesh, ct_ymesh and ct_zmesh are vectors and not
% matrices. This allow to run this functions also in "low" memory pcs.
%
% See also dicomrt_loaddose, dicomrt_getPatientPosition
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org)

% Sort CT slices first
%
% load ct slices info

% Check number of argument and set-up some parameters and variables
error(nargchk(1,2,nargin))

if exist('sorting')==0
    sorting=1; % perform sorting check
end

% Retrieve the number of images
nlines=dicomrt_nASCIIlines(filename);

if nlines>1
    disp('Loading CT slice information ...');
    [filelist,xlocation,ylocation,zlocation,modifUID,user_request] = dicomrt_loadctlist(filename);
    if user_request==1;
        return
    end
    disp('CT slice information loaded.');

    if sorting==1
        % sort ct slices
        disp('Sorting CT slices ...');
        [modifZ,user_request]=dicomrt_sortct(filelist,xlocation,ylocation,zlocation,filename);
        if user_request==1;
            return
        end
        disp('CT slices sorted.');
    else
        modifZ=0;
        modifUID=0;
    end

    if modifZ~=0 | modifUID~=0 % a modification to the filelist was made by dicomrt_sortct
        filename_sorted=[filename,'.sort.txt'];
    else % no modification have been made
        filename_sorted=filename;
    end
else
    disp('Loading one image. Zmesh will have no sense. Slice position can be loaded using dicominfo.');
    filename_sorted=filename;
end

% Now get CT images and create 3D Volume

% Set parameters
CToffset=1000;
nct=0;

% Define cell array to store info
case_study_info=cell(1);

%loop until the end-of-file is reached and build 3D CT matrix
disp('Loading ct volume ...');

% Progress bar
h = waitbar(0,['Loading progress:']);
set(h,'Name','dicomrt_loadct: loading CT images');

fid=fopen(filename_sorted);

while (feof(fid)~=1);
    clear info_temp temp
    nct=nct+1; % counting
    nctcheck=nct; % check for eof
    ct_file_location{1,nct}=fgetl(fid);
    if isnumeric(ct_file_location{1,nct}), nct=nct-1; break, end %end of line reached
    
    temp=dicomread(deblank(ct_file_location{1,nct}));

    dictFlg = checkDictUse;
    if dictFlg
        info_temp=dicominfo(deblank(ct_file_location{1,nct}),'dictionary', 'ES - IPT4.1CompatibleDictionary.mat');
    else
        info_temp=dicominfo(deblank(ct_file_location{1,nct}));
    end


    zmesh(nct)=info_temp.ImagePositionPatient(3);
    
    if isfield(info_temp,'RescaleSlope')~=0 | isfield(info_temp,'RescaleIntercept')~=0
        temp=double(temp)*info_temp.RescaleSlope+info_temp.RescaleIntercept+CToffset;
    else
        warning('dicomrt_loadct: no DICOM Rescale data were found. Assuming RescaleSlope = 1, RescaleIntercept = 0 and CToffset = 1000');
        temp=double(temp);
    end
    
    case_study_info{nct}=info_temp;
    case_study(:,:,nct)=uint16(temp);
    waitbar(nct/nlines,h);
end

% Make zmesh a column vector
zmesh=dicomrt_makevertical(zmesh);

fclose(fid);

if nctcheck~=nct;
    warning('dicomrt_loadct: End of file was prematurely reached. Check the expected dimensions of your data. It may be OK to continue');
end

[PatientPositionCODE]=dicomrt_getPatientPosition(info_temp);

% PatientOrientation     ImageOrientationPatient
%
% HFS                    (1,0,0) (0,1,0)
% FFS                    (1,0,0) (0,1,0)
% HFP                    (-1,0,0) (0,-1,0)
% FFP                    (-1,0,0) (0,-1,0)
%
%
if PatientPositionCODE == 1 | PatientPositionCODE == 2
    min_x=info_temp.ImagePositionPatient(1);
    pixel_spacing_x=info_temp.PixelSpacing(1);

    min_y=info_temp.ImagePositionPatient(2);
    pixel_spacing_y=info_temp.PixelSpacing(2);

    [xmesh] = dicomrt_create1dmesh(min_x,pixel_spacing_x,size(temp,2),0);
    [ymesh] = dicomrt_create1dmesh(min_y,pixel_spacing_y,size(temp,1),0);

else
    max_x=info_temp.ImagePositionPatient(1);
    pixel_spacing_x=info_temp.PixelSpacing(1);

    max_y=info_temp.ImagePositionPatient(2);
    pixel_spacing_y=info_temp.PixelSpacing(2);

    [xmesh] = dicomrt_create1dmesh(max_x,pixel_spacing_x,size(temp,1),1);
    [ymesh] = dicomrt_create1dmesh(max_y,pixel_spacing_y,size(temp,2),1);

end

ct_zmesh=dicomrt_mmdigit(zmesh*0.1,7);
ct_ymesh=dicomrt_mmdigit(ymesh*0.1,7);
ct_xmesh=dicomrt_mmdigit(xmesh*0.1,7);

disp('Loading complete ...');

% 3D CT matrix and mesh matrix imported
%
% Some CT images info have private tags or fragmented info.
% If so, go into manual mode.
%

% Check support for current Patient Position
if PatientPositionCODE == 1 % supported Patient Position: HFS
    disp('dicomrt_loadct: Patient Position is Head First Supine (HFS).');
elseif PatientPositionCODE == 2 % supported Patient Position: FFS
    disp('dicomrt_loadct: Patient Position is Feet First Supine (FFS).');
elseif PatientPositionCODE == 3 % unsupported Patient Position: HFP
    disp('dicomrt_loadct: Patient Position is Head First Prone (HFP).');
elseif PatientPositionCODE == 4 % unsupported Patient Position: FFP
    disp('dicomrt_loadct: Patient Position is Feet First Prone (FFP).');
else
    warning('Unable to determine Patient Position');
    PatientPosition=input('dicomrt_loadct: Please specify Patient Position: HFS(default),FFS,HFP,FFP: ','s');
    if isempty(PatientPosition)==1
        PatientPosition='HFS';
    end

    if strcmpi(PatientPosition, 'HFS')
        PatientPositionCODE = 1;
    elseif strcmpi(PatientPosition, 'FFS')
        PatientPositionCODE = 2;
    elseif strcmpi(PatientPosition, 'HFP')
        PatientPositionCODE = 3;
    elseif strcmpi(PatientPosition, 'FFP')
        PatientPositionCODE = 4;
    end

end

% Create cell array
ctcell=cell(3,1);
ctcell{1,1}=case_study_info;
ctcell{2,1}=case_study;
ctcell{3,1}=[];

% Close progress bar
close(h);
pack
