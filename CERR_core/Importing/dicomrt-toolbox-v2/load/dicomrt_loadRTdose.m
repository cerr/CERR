function [cell_case_study,xmesh,ymesh,zmesh] = dicomrt_loadRTdose(filename_list,force)
% dicomrt_loadRTdose(filename_list,force)
%
% Read dicom dose for a case study using MATLAB native function dicomread.
%
% filename contains a list of dose matrices to import.
% filename does not contain link to an RTPLAN in the first line
%
% Dose matrices are stored in a single 3D matrix: case_study
% x-y-z coordinates of the center of the dose-pixel are stored in xmesh,ymesh,zmesh
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
% NOTE: this function and dicomrt_loaddose differs because in this case the
% RTPLAN is not imported and left black
%
%
% See also dicomrt_loadct, dicomrt_getPatientPosition
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org)

% Retrieve the number of images
nlines=dicomrt_nASCIIlines(filename_list);

% Get dose images and create 3D Volume
fid=fopen(filename_list);
nfiles=0;
skip_header_mf=0;
DoseGridScaling_mf=1;
case_study=[];
CELLStore=0;

% import plan information
rtplan_location=fgetl(fid);

dictFlg = checkDictUse;
if dictFlg
    rtplan=dicominfo(rtplan_location, 'dictionary', 'ES - IPT4.1CompatibleDictionary.mat');
else
    rtplan=dicominfo(rtplan_location);
end



% retrieve number of beams and beam labels
beams=fieldnames(rtplan.BeamSequence);
nbeams=size(beams,1);

% Define cell array to store info
case_study_info=cell(1);
case_study_info{1}=rtplan;

if exist('force')==0
    [PatientPositionCODE]=dicomrt_getPatientPosition(rtplan);
elseif exist('force')~=0
    if force==0;
        [PatientPositionCODE]=dicomrt_getPatientPosition(rtplan);
    end
else
    warning('dicomrt_loaddose: Dicom load was forced. No PatientPosition check is performed!');
end

try
    fractions=rtplan.FractionGroupSequence.Item_1.NumberOfFractionsPlanned;
    if isempty(fractions)==1
        fractions=1;
    end
catch
    disp('This is a single franction plan');
    fractions=1;
end

% Progress bar
h = waitbar(0,['Loading progress:']);
set(h,'Name','dicomrt_loaddose: loading RTDOSE objects');

% loop until the end-of-file is reached and build 3D dose matrix
while (feof(fid)~=1);
    nfiles=nfiles+1; % counting
    nfilescheck=nfiles; % check for eof
    file_location{1,nfiles}=fgetl(fid);
    if isnumeric(file_location{1,nfiles}), nfiles=nfiles-1, break, end % end of line reached

    dictFlg = checkDictUse;
    if dictFlg
        info_image=dicominfo(file_location{1,nfiles}, 'dictionary', 'ES - IPT4.1CompatibleDictionary.mat'); % import dose information
    else
        info_image=dicominfo(file_location{1,nfiles});
    end


    try
        image=dicomread(file_location{1,nfiles}); % import pixel data
        dimage=double(squeeze(image)); % convert pixel data to double
    catch
        dictFlg = checkDictUse;
        if dictFlg
            info_image_mf=dicominfo(file_location{1,nfiles}, 'dictionary', 'ES - IPT4.1CompatibleDictionary.mat');
        else
            info_image_mf=dicominfo(file_location{1,nfiles});
        end

        DoseGridScaling_mf=info_image_mf.DoseGridScaling;
        skip_header_mf=1;
        % Give option to load individual beam/segments or total dose
        disp('This appear to be a Multi-frame study with dose contribution');
        disp('Do you want to:');
        disp('(1) load the dose matrix as a sum of all beams [default]');
        disp('(2) keep individual dose contribution');
        % with option (2) it is supposed that only beam contribution is exported
        % no support for segment contribution is given for the time being
        % because no TPS is currently capable of doing this
        STOREoption = input('Option: ');
        if STOREoption == 2
            CELLStore = 1;
            case_study = cell(nbeams,2);
        else
            CELLStore = 0;
        end
    end
    if skip_header_mf==1 & nfiles==1
    elseif skip_header_mf==1 & nfiles>1 & CELLStore == 1
        % Multi-frame with dose contribution
        if strcmpi(info_image.DoseSummationType,'FRACTION')==1 | ...
                strcmpi(info_image.DoseSummationType,'BEAM')==1
            dimage=dimage.*info_image.DoseGridScaling.*DoseGridScaling_mf;
        elseif strcmpi(info_image.DoseSummationType,'PLAN')==1
            dimage=dimage./info_image.DoseGridScaling.*fractions.*DoseGridScaling_mf;
        end
        case_study_info{nfiles}=info_image;
        case_study{nfiles-1,1}=getfield(rtplan,'BeamSequence',char(beams(nfiles-1)),'BeamName');
        case_study{nfiles-1,2}=dimage;
        zmesh=info_image.ImagePositionPatient(3)+info_image.GridFrameOffsetVector;
    elseif skip_header_mf==1 & nfiles>1 & CELLStore == 0
        % Multi-frame with dose contribution
        if strcmpi(info_image.DoseSummationType,'FRACTION')==1 | ...
                strcmpi(info_image.DoseSummationType,'BEAM')==1
            dimage=dimage.*info_image.DoseGridScaling.*DoseGridScaling_mf;
        elseif strcmpi(info_image.DoseSummationType,'PLAN')==1
            dimage=dimage./info_image.DoseGridScaling.*fractions.*DoseGridScaling_mf;
        end
        case_study_info{nfiles+1}=info_image;
        if length(case_study)==0
            case_study=dimage;
        else
            case_study=case_study+dimage;
        end
        zmesh=info_image.ImagePositionPatient(3)+info_image.GridFrameOffsetVector;
    elseif  skip_header_mf==0
        if length(size(image))==4
            % this is a Multi-frame study without dose components
            if strcmpi(info_image.DoseSummationType,'FRACTION')==1 | ...
                    strcmpi(info_image.DoseSummationType,'BEAM')==1
                dimage=dimage.*info_image.DoseGridScaling.*DoseGridScaling_mf;
            elseif strcmpi(info_image.DoseSummationType,'PLAN')==1
                dimage=dimage./info_image.DoseGridScaling.*fractions.*DoseGridScaling_mf;
            end
            case_study_info{nfiles+1}=info_image;
            case_study=dimage;
            zmesh=info_image.ImagePositionPatient(3)+info_image.GridFrameOffsetVector;
        else % not a multi-frame !
            if strcmpi(info_image.DoseSummationType,'FRACTION')==1 | ...
                    strcmpi(info_image.DoseSummationType,'BEAM')==1
                dimage=dimage.*info_image.DoseGridScaling.*DoseGridScaling_mf;
            elseif strcmpi(info_image.DoseSummationType,'PLAN')==1
                dimage=dimage./info_image.DoseGridScaling.*fractions.*DoseGridScaling_mf;
            end
            case_study_info{nfiles+1}=info_image;
            case_study(:,:,nfiles)=dimage;
            zmesh(nfiles)=info_image.ImagePositionPatient(3);
        end
    end
    waitbar(nfiles/nlines,h);
end

% Make zmesh a column vector
zmesh=dicomrt_makevertical(zmesh);

fclose(fid);

if nfilescheck~=nfiles;
    warning('dicomrt_loaddose: End of file was prematurely reached. Check the expected dimensions of your data. It may be OK to continue');
end

% PatientOrientation     ImageOrientationPatient
%
% HFS                    (1,0,0) (0,1,0)
% FFS                    (1,0,0) (0,1,0)
% HFP                    (-1,0,0) (0,-1,0)
% FFP                    (-1,0,0) (0,-1,0)
%
%
if PatientPositionCODE == 1 | PatientPositionCODE == 2
    min_x=info_image.ImagePositionPatient(1);
    pixel_spacing_x=info_image.PixelSpacing(1);

    min_y=info_image.ImagePositionPatient(2);
    pixel_spacing_y=info_image.PixelSpacing(2);

    [xmesh] = dicomrt_create1dmesh(min_x,pixel_spacing_x,size(image,2),0);
    [ymesh] = dicomrt_create1dmesh(min_y,pixel_spacing_y,size(image,1),0);

else
    max_x=info_image.ImagePositionPatient(1);
    pixel_spacing_x=info_image.PixelSpacing(1);

    max_y=info_image.ImagePositionPatient(2);
    pixel_spacing_y=info_image.PixelSpacing(2);

    [xmesh] = dicomrt_create1dmesh(max_x,pixel_spacing_x,size(image,2),1);
    [ymesh] = dicomrt_create1dmesh(max_y,pixel_spacing_y,size(image,1),1);

end

zmesh=dicomrt_mmdigit(zmesh*0.1,7);
ymesh=dicomrt_mmdigit(ymesh*0.1,7);
xmesh=dicomrt_mmdigit(xmesh*0.1,7);

% Check support for current Patient Position
if PatientPositionCODE == 1 % supported Patient Position: HFS
    disp('dicomrt_loadRTdose: Patient Position is Head First Supine (HFS).');
elseif PatientPositionCODE == 2 % supported Patient Position: FFS
    disp('dicomrt_loadRTdose: Patient Position is Feet First Supine (FFS).');
elseif PatientPositionCODE == 3 % supported Patient Position: HFP
    disp('dicomrt_loadRTdose: Patient Position is Head First Prone (HFP).');
elseif PatientPositionCODE == 4 % supported Patient Position: FFP
    disp('dicomrt_loadRTdose: Patient Position is Feet First Prone (FFP).');
else
    warning('dicomrt_loaddose: Unable to determine Patient Position');
    PatientPosition=input('dicomrt_loadRTdose: Please specify Patient Position: HFS(default),FFS,HFP,FFP: ','s');
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

% Create a cell array where to store rtplan and dose matrix
cell_case_study=cell(3,1);
cell_case_study{1,1}=case_study_info;
cell_case_study{2,1}=case_study;
cell_case_study{3,1}=[];
% Completed

% Close progress bar
close(h);
