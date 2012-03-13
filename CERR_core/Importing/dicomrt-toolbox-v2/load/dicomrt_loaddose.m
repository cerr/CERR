function [cell_case_study,xmesh,ymesh,zmesh] = dicomrt_loaddose(filename_list,force)
% dicomrt_loaddose(filename_list,force)
%
% Read dicom dose for a case using MATLAB native function dicomread.
%
% filename contains a list of dose matrices to import.
%
% NOTE1:the first file listed in filename_list MUST BE the rtplan file.
%       rtplan is an essential source of information for the analysis of
%       dose distribution and DVH calculation. Therefore is needed.
% NOTE2:CT slices are normally sent (and listed) in filename_list from the
%       the most negative to the most positive ZLocation.
% NOTE3:as opposed to dicomrt_loaddodse *mesh* arguments are vectors and not
% matrices. This allow to run this functions also in "low" memory pcs.
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
% See also dicomrt_loadct, dicomrt_getPatientPosition
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org)
% LM DK 04/25/06
%       added check for patient position in function askzmesh. Caused bug
%       when patient position was other than HFS

% Retrieve the number of images
nlines=dicomrt_nASCIIlines(filename_list);

% Get dose images and create 3D Volume
fid=fopen(filename_list);

% import plan information
rtplan_location=fgetl(fid);

dictFlg = checkDictUse;
if dictFlg
    rtplan=dicominfo(rtplan_location,'dictionary', 'ES - IPT4.1CompatibleDictionary.mat');
else
    rtplan=dicominfo(rtplan_location);
end



fractionGroups=fieldnames(rtplan.FractionGroupSequence);

if size(fractionGroups,1)>1
    warning('dicomrt_loaddose: There are more than one fraction group. Working on fraction group 1.');
end

nbrachy=getfield(rtplan,'FractionGroupSequence',char(fractionGroups(1)),'NumberOfBrachyApplicationSetups');
nbeams=getfield(rtplan,'FractionGroupSequence',char(fractionGroups(1)),'NumberOfBeams');

if nbrachy>0
    disp('dicomrt_loaddose: This is BRACHY treatment !');
else
    disp('dicomrt_loaddose: This is an EXTERNAL BEAM treatment !');
end


if exist('force')==0
    [PatientPositionCODE]=dicomrt_getPatientPosition(rtplan);
elseif exist('force')~=0
    if force==0;
        [PatientPositionCODE]=dicomrt_getPatientPosition(rtplan);
    end
else
    warning('dicomrt_loaddose: Dicom load was forced. No PatientPosition check is performed!');
end

% Define cell array to store info
case_study_info_rtplan=cell(1);
case_study_info_rtplan{1}=rtplan;

% Number of dose files to load
nfiles=nlines-1;

[case_study_info,case_study,zmesh,info_image]=loaddose(fid,nfiles,PatientPositionCODE);

case_study_info{1}=case_study_info_rtplan{1};

% Make zmesh a column vector
zmesh=dicomrt_makevertical(zmesh);

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

    [xmesh] = dicomrt_create1dmesh(min_x,pixel_spacing_x,info_image.Columns,0);
    [ymesh] = dicomrt_create1dmesh(min_y,pixel_spacing_y,info_image.Rows,0);

else
    max_x=info_image.ImagePositionPatient(1);
    pixel_spacing_x=info_image.PixelSpacing(1);

    max_y=info_image.ImagePositionPatient(2);
    pixel_spacing_y=info_image.PixelSpacing(2);

    [xmesh] = dicomrt_create1dmesh(max_x,pixel_spacing_x,info_image.Columns,1);
    [ymesh] = dicomrt_create1dmesh(max_y,pixel_spacing_y,info_image.Rows,1);

end

zmesh=dicomrt_mmdigit(zmesh*0.1,7);
ymesh=dicomrt_mmdigit(ymesh*0.1,7);
xmesh=dicomrt_mmdigit(xmesh*0.1,7);

% Check support for current Patient Position
if PatientPositionCODE == 1 % supported Patient Position: HFS
    disp('dicomrt_loaddose: Patient Position is Head First Supine (HFS).');
elseif PatientPositionCODE == 2 % supported Patient Position: FFS
    disp('dicomrt_loaddose: Patient Position is Feet First Supine (FFS).');
elseif PatientPositionCODE == 3 % supported Patient Position: HFP
    disp('dicomrt_loaddose: Patient Position is Head First Prone (HFP).');
elseif PatientPositionCODE == 4 % supported Patient Position: FFP
    disp('dicomrt_loaddose: Patient Position is Feet First Prone (FFP).');
else
    warning('dicomrt_loaddose: Unable to determine Patient Position');
    PatientPosition=input('dicomrt_loaddose: Please specify Patient Position: HFS(default),FFS,HFP,FFP: ','s');
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


function [case_study_info,case_study,zmesh,info_image]=loaddose(fid,nfiles,PatientPositionCODE)

case_study=[];
case_study_info=cell(1);

% Progress bar
h = waitbar(0,['Loading progress:']);
set(h,'Name','dicomrt_loaddose: loading RTDOSE objects');

for k=1:nfiles
    switch k
        % FIRST FILE
        case 1
            file_location{1,k}=fgetl(fid);
            dictFlg = checkDictUse;
            if dictFlg
                info_image=dicominfo(file_location{1,k},'dictionary', 'ES - IPT4.1CompatibleDictionary.mat'); % import file information
            else
                info_image=dicominfo(file_location{1,k});
            end

            doseSummationType=info_image.DoseSummationType;
            if strcmpi(doseSummationType,'PLAN') | strcmpi(doseSummationType,'TMSPLAN')
                
                doseImage=dicomread(file_location{1,k}); % import pixel data
                
                switch ndims(doseImage)
                    % NON MULTI FRAME
                    case 2
                        % convert pixel data to double
                        dimage=double(doseImage);
                        % multiply by scaling factor
                        dimage=dimage.*info_image.DoseGridScaling;
                        % store data into output variable
                        case_study_info{k+1}=info_image;
                        case_study(:,:,k)=dimage;
                        % store zmesh
                        zmesh(k)=info_image.ImagePositionPatient(3);

                        % MULTI FRAME
                    case 4
                        % convert pixel data to double
                        dimage=double(squeeze(doseImage));
                        % multiply by scaling factor
                        dimage=dimage.*info_image.DoseGridScaling;
                        zmesh=askZmesh(info_image,PatientPositionCODE);
                        % make sure doseImage and zmesh have the same
                        % dimension. To be investigated further.
                        try
                            dimage=dimage(:,:,1:length(zmesh));
                        catch

                        end
                        % store data into output variable
                        case_study_info{k+1}=info_image;
                        if length(case_study)==0
                            case_study=dimage;
                        else
                            case_study=case_study+dimage;
                        end
                end
            elseif strcmpi(doseSummationType,'BEAM')
                
                doseImage=dicomread(file_location{1,k}); % import pixel data
                
                MFquestion=questdlg('This appear to be a Multi-frame study with BEAM dose contribution. Do you want to:',...
                    'Load option','keep individual dose contribution (default)',...
                    'load the dose matrix as a sum of all beams', 'keep individual dose contribution (default)');
                switch MFquestion,
                    case {'keep individual dose contribution (default)',''}
                        hwarning=warndlg('Sorry, we are still working on this option. Loading the dose matrix as a sum of all beams');
                        waitfor(hwarning);
                        %case_study = cell(nbeams,2);
                        % convert pixel data to double
                        %dimage=double(squeeze(doseImage));
                        % multiply by scaling factor
                        %dimage=dimage.*info_image.DoseGridScaling;
                        % store data into output variable
                        %case_study_info{k}=info_image;
                        %case_study{k,1}=getfield(rtplan,'BeamSequence',char(beams(k)),'BeamName');
                        %case_study{k,2}=dimage;
                        % store zmesh
                        %zmesh=info_image.GridFrameOffsetVector;
                        %%%%%%%TO REMOVE LATER%%%%%%%%%%%%%%%%
                        % convert pixel data to double
                        dimage=double(squeeze(doseImage));
                        % multiply by scaling factor
                        dimage=dimage.*info_image.DoseGridScaling;
                        % store zmesh
                        zmesh=askZmesh(info_image,PatientPositionCODE);
                        % make sure doseImage and zmesh have the same
                        % dimension. To be investigated further.
                        dimage=dimage(:,:,1:length(zmesh));
                        % store data into output variable
                        case_study_info{k+1}=info_image;
                        if length(case_study)==0
                            case_study=dimage;
                        else
                            case_study=case_study+dimage;
                        end
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    case 'load the dose matrix as a sum of all beams'
                        % convert pixel data to double
                        dimage=double(squeeze(doseImage));
                        % multiply by scaling factor
                        dimage=dimage.*info_image.DoseGridScaling;
                        % store zmesh
                        zmesh=askZmesh(info_image,PatientPositionCODE);
                        % make sure doseImage and zmesh have the same
                        % dimension. To be investigated further.
                        dimage=dimage(:,:,1:length(zmesh));
                        % store data into output variable
                        case_study_info{k+1}=info_image;
                        if length(case_study)==0
                            case_study=dimage;
                        else
                            case_study=case_study+dimage;
                        end
                end
            elseif strcmpi(doseSummationType,'FRACTION')
                doseImage=dicomread(file_location{1,k}); % import pixel data
                % convert pixel data to double
                dimage=double(squeeze(doseImage));
                % multiply by scaling factor
                dimage=dimage.*info_image.DoseGridScaling;
                % store zmesh
                zmesh=askZmesh(info_image,PatientPositionCODE);
                % make sure doseImage and zmesh have the same
                % dimension. To be investigated further.
                dimage=dimage(:,:,1:length(zmesh));
                % store data into output variable
                case_study_info{k+1}=info_image;
                if length(case_study)==0
                    case_study=dimage;
                else
                    case_study=case_study+dimage;
                end
            elseif strcmpi(doseSummationType,'BRACHY')
                doseImage=dicomread(file_location{1,k}); % import pixel data
                % convert pixel data to double
                dimage=double(squeeze(doseImage));
                % multiply by scaling factor
                dimage=dimage.*info_image.DoseGridScaling;
                % store zmesh
                zmesh=askZmesh(info_image,PatientPositionCODE);
                % make sure doseImage and zmesh have the same
                % dimension. To be investigated further.
                dimage=dimage(:,:,1:length(zmesh));
                % store data into output variable
                case_study_info{k+1}=info_image;
                if length(case_study)==0
                    case_study=dimage;
                else
                    case_study=case_study+dimage;
                end
            end
        otherwise
            file_location{1,k}=fgetl(fid);
            dictFlg = checkDictUse;
            if dictFlg
                info_image=dicominfo(file_location{1,k},'dictionary', 'ES - IPT4.1CompatibleDictionary.mat'); % import file information
            else
                info_image=dicominfo(file_location{1,k});
            end


            doseSummationType=info_image.DoseSummationType;
            if strcmpi(doseSummationType,'PLAN') | strcmpi(doseSummationType,'TMSPLAN')
                doseImage=dicomread(file_location{1,k}); % import pixel data
                switch ndims(doseImage)
                    % NON MULTI FRAME
                    case 2
                        % convert pixel data to double
                        dimage=double(doseImage);
                        % multiply by scaling factor
                        dimage=dimage.*info_image.DoseGridScaling;
                        % store zmesh
                        zmesh(k)=info_image.ImagePositionPatient(3);
                        % store data into output variable
                        case_study_info{k+1}=info_image;
                        case_study(:,:,k)=dimage;
                        % MULTI FRAME
                    case 4
                        % convert pixel data to double
                        dimage=double(squeeze(doseImage));
                        % multiply by scaling factor
                        dimage=dimage.*info_image.DoseGridScaling;
                        % make sure doseImage and zmesh have the same
                        % dimension. To be investigated further.
                        dimage=dimage(:,:,1:length(zmesh));
                        % store data into output variable
                        case_study_info{k+1}=info_image;
                        if length(case_study)==0
                            case_study=dimage;
                        else
                            case_study=case_study+dimage;
                        end
                end
            elseif strcmpi(doseSummationType,'BEAM')
                doseImage=dicomread(file_location{1,k}); % import pixel data
                switch MFquestion,
                    case {'keep individual dose contribution (default)',''}
                        %case_study = cell(nbeams,2);
                        % convert pixel data to double
                        %dimage=double(squeeze(doseImage));
                        % multiply by scaling factor
                        %dimage=dimage.*info_image.DoseGridScaling;
                        % store data into output variable
                        %case_study_info{k}=info_image;
                        %case_study{k,1}=getfield(rtplan,'BeamSequence',char(beams(k)),'BeamName');
                        %case_study{k,2}=dimage;
                        % store zmesh
                        %zmesh=info_image.GridFrameOffsetVector;
                        %%%%%%%TO REMOVE LATER%%%%%%%%%%%%%%%%
                        % convert pixel data to double
                        dimage=double(squeeze(doseImage));
                        % multiply by scaling factor
                        dimage=dimage.*info_image.DoseGridScaling;
                        % make sure doseImage and zmesh have the same
                        % dimension. To be investigated further.
                        dimage=dimage(:,:,1:length(zmesh));
                        % store data into output variable
                        case_study_info{k+1}=info_image;
                        if length(case_study)==0
                            case_study=dimage;
                        else
                            case_study=case_study+dimage;
                        end
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    case 'load the dose matrix as a sum of all beams'
                        % convert pixel data to double
                        dimage=double(squeeze(doseImage));
                        % multiply by scaling factor
                        dimage=dimage.*info_image.DoseGridScaling;
                        % make sure doseImage and zmesh have the same
                        % dimension. To be investigated further.
                        dimage=dimage(:,:,1:length(zmesh));
                        % store data into output variable
                        case_study_info{k+1}=info_image;
                        if length(case_study)==0
                            case_study=dimage;
                        else
                            case_study=case_study+dimage;
                        end
                end
            elseif strcmpi(doseSummationType,'FRACTION')
                doseImage=dicomread(file_location{1,k}); % import pixel data
                % convert pixel data to double
                dimage=double(squeeze(doseImage));
                % multiply by scaling factor
                dimage=dimage.*info_image.DoseGridScaling;
                % make sure doseImage and zmesh have the same
                % dimension. To be investigated further.
                dimage=dimage(:,:,1:length(zmesh));
                % store data into output variable
                case_study_info{k+1}=info_image;
                if length(case_study)==0
                    case_study=dimage;
                else
                    case_study=case_study+dimage;
                end
            elseif strcmpi(doseSummationType,'BRACHY')
                doseImage=dicomread(file_location{1,k}); % import pixel data
                % convert pixel data to double
                dimage=double(squeeze(doseImage));
                % multiply by scaling factor
                dimage=dimage.*info_image.DoseGridScaling;
                % make sure doseImage and zmesh have the same
                % dimension. To be investigated further.
                dimage=dimage(:,:,1:length(zmesh));
                % store data into output variable
                case_study_info{k+1}=info_image;
                if length(case_study)==0
                    case_study=dimage;
                else
                    case_study=case_study+dimage;
                end
            end
    end
    waitbar(k/nfiles,h);
end

% Close file
fclose(fid);

% Close progress bar
close(h);

function [zmesh]=askZmesh(info_image,PatientPositionCODE)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% Bypassing question as per Dr Bosh Recommendation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% sentence1=horzcat('This appear to be a Multi-frame study.',...
% 	'Following the DICOM standard the parameter Grid Frame Offset Vector represents ',...
% 	'an array which contains the z coordinates (in mm) of the image frames in a multiframe dose.');
% hline='';
% sentence2=horzcat('Instead this vector is often used to represent an Offset to add to the ImagePositionPatient data.',...
% 	'You can choose how to use the Grid Frame Offset Vector.');
% sentence3='If you are unsure about this option please check the DICOM Conformance Statement of your vendor.';
% hline='';
% question=char(sentence1,hline,sentence2,hline,sentence3);
% Zwarndlg=warndlg(question);
% waitfor(Zwarndlg);
%
% Zquestion=questdlg('Choose the use of the Grid Frame Offset Vector:', 'Grid Frame Offset Vector option',...
% 	 'Z - Offset (default)','Z coordinate', 'Z - Offset (default)');
% switch Zquestion,
% 	case {'Z coordinate',''}
% 		zmesh=info_image.GridFrameOffsetVector;
%     otherwise
%         switch PatientPositionCODE
%             case 1% HFS
%                 zmesh=info_image.ImagePositionPatient(3)+info_image.GridFrameOffsetVector;
%             case 2% FFS
%                 zmesh=info_image.ImagePositionPatient(3)-info_image.GridFrameOffsetVector;
%             case 3% HFP
%                 zmesh=info_image.ImagePositionPatient(3)+info_image.GridFrameOffsetVector;
%             case 4% FFP
%                 zmesh=info_image.ImagePositionPatient(3)-info_image.GridFrameOffsetVector;
%         end
% end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if info_image.GridFrameOffsetVector(1) == 0
    switch PatientPositionCODE
        case 1% HFS
            zmesh=info_image.ImagePositionPatient(3)+info_image.GridFrameOffsetVector;
        case 2% FFS
            zmesh=info_image.ImagePositionPatient(3)-info_image.GridFrameOffsetVector;
        case 3% HFP
            zmesh=info_image.ImagePositionPatient(3)+info_image.GridFrameOffsetVector;
        case 4% FFP
            zmesh=info_image.ImagePositionPatient(3)-info_image.GridFrameOffsetVector;
    end
else
    zmesh=info_image.GridFrameOffsetVector;
end
