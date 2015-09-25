% multiDoseImport
%
% Brings multi DICOM dose files into a plan.Workflow is that first you
% select your CERR plan file that you want to use to merge all the doses.
% Next script will ask you to select the directory where all the dose files
% are. This script will the automatically import all the DICOM dose into
% this plan.
%
% Written DK 04/27/2007
%
% Copyright 2010, Joseph O. Deasy, on behalf of the CERR development team.
% 
% This file is part of The Computational Environment for Radiotherapy Research (CERR).
% 
% CERR development has been led by:  Aditya Apte, Divya Khullar, James Alaly, and Joseph O. Deasy.
% 
% CERR has been financially supported by the US National Institutes of Health under multiple grants.
% 
% CERR is distributed under the terms of the Lesser GNU Public License. 
% 
%     This version of CERR is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
% CERR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
% without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with CERR.  If not, see <http://www.gnu.org/licenses/>.

[filename pathname] = uigetfile({'*.mat;*.mat.bz2;*.mat.tar;*.mat.tar.bz2', 'CERR Plans (*.mat, *.mat.bz2, *.mat.tar, *.mat.tar.bz2)';'*.*', 'All Files (*.*)'}, 'Select a CERR Plan file');

file = fullfile(pathname,filename);

if filename == 0
    CERRStatusString('Open cancelled. Ready.');
    return
end

[pathstr, name, ext] = fileparts(file);

if strcmpi(ext, '.bz2')
    zipFile = 1;
    CERRStatusString(['Decompressing ' name ext '...']);
    outstr = gnuCERRCompression(file, 'uncompress');
    loadfile = fullfile(pathstr, name);

    [pathstr, name, ext] = fileparts(fullfile(pathstr, name));

else
    zipFile = 0;
    loadfile = file;
end

CERRStatusString(['Loading ' name ext '...']);

%Decompress files if .tar
if strcmpi(ext, '.tar')
    currentDir = cd;
    cd(tempdir);
    tarPath = fullfile(getCERRPath,'Compression','tar.exe');
    tarFile = file;
    tarFile(strfind(tarFile, '\')) = '/';
    if ispc
        dos([tarPath ' -x < "' tarFile '"']);
    elseif isunix
        unix([tarPath ' -x < "' tarFile '"']);
    end
    cd(currentDir)

    loadfile = fullfile(tempdir, name);
end

planC           = load(loadfile,'planC');
if zipFile
    delete(loadfile);
end
planC           = planC.planC; %Conversion from struct created by load
stateS.CERRFile = file;
stateS.workspacePlan = 0;

indexS = planC{end};

scanUID = planC{indexS.scan}(1).scanUID;

doseDir = uigetdir('C:','Select Directory where you have Dose files');

dosefiles = dir(doseDir);

dosefiles([dosefiles.isdir]) = [];

doseInitS = initializeCERR('dose');
for i = 1:length(planC{indexS.dose})
    doseInitS = dissimilarInsert(doseInitS,planC{indexS.dose}(i));
end

oldDoseLen = length(planC{indexS.dose});

for j = 1:length(dosefiles)

    i = j + oldDoseLen;



    info_image=dicominfo(fullfile(doseDir ,dosefiles(j).name));
    doseImage=squeeze(dicomread(fullfile(doseDir ,dosefiles(j).name)));
    doseImage=doseImage.*info_image.DoseGridScaling;
    zmesh=info_image.ImagePositionPatient(3)+info_image.GridFrameOffsetVector;

    min_x=info_image.ImagePositionPatient(1);
    pixel_spacing_x=info_image.PixelSpacing(1);

    min_y=info_image.ImagePositionPatient(2);
    pixel_spacing_y=info_image.PixelSpacing(2);

    [xmesh] = dicomrt_create1dmesh(min_x,pixel_spacing_x,info_image.Columns,0);
    [ymesh] = dicomrt_create1dmesh(min_y,pixel_spacing_y,info_image.Rows,0);

    zmesh=dicomrt_mmdigit(zmesh*0.1,7);
    ymesh=dicomrt_mmdigit(ymesh*0.1,7);
    xmesh=dicomrt_mmdigit(xmesh*0.1,7);

    tags = dicomrt_d2c_rtogtags;

    xmesh                       = xmesh;
    ymesh                       = -ymesh;
    zmesh                       = -zmesh;
    zmesh                       = flipdim(zmesh,1);
    %zmesh                       = zmesh-zmesh(1); % set origin to the first image transmitted
    tags.coord1OFFirstPoint     = xmesh(1);
    tags.coord2OFFirstPoint     = ymesh(1);
    temp_diff_x                 = diff(xmesh);
    temp_diff_y                 = diff(ymesh);
    tags.horizontalGridInterval = temp_diff_x(1);
    tags.verticalGridInterval   = temp_diff_y(1);




    doseInitS(i).imageNumber            = tags.nimages + 1;
    doseInitS(i).imageType              = 'dose';
    doseInitS(i).caseNumber             = 1;               % ALWAYS ONE. DICOM-RT DOSE IS TOTAL DOSE
    doseInitS(i).patientName            = [info_image.PatientName.FamilyName];
    try
        doseInitS(i).patientName     = [doseInitS(i).patientName,' ', ...
            info_image.PatientName.GivenName]; % may be not present in anonymized studies
    end
    doseInitS(i).doseNumber             = 1;               % ALWAYS ONE. DICOM-RT DOSE IS TOTAL DOSE
    doseInitS(i).doseType               = info_image.DoseType;
    doseInitS(i).doseUnits              = info_image.DoseUnits;
    doseInitS(i).doseScale              = 1;

    doseInitS(i).planIDOfOrigin        = dosefiles(j).name;

    doseInitS(i).fractionGroupID        = dosefiles(j).name;

    doseInitS(i).orientationOfDose      = 'TRANSVERSE';    % LEAVE FOR NOW
    doseInitS(i).numberRepresentation   = 'CHARACTER';     % LEAVE FOR NOW
    doseInitS(i).numberOfDimensions     = ndims(doseImage);
    doseInitS(i).sizeOfDimension1       = size(doseImage,2);
    doseInitS(i).sizeOfDimension2       = size(doseImage,1);
    doseInitS(i).sizeOfDimension3       = size(doseImage,3);
    doseInitS(i).coord1OFFirstPoint     = tags.coord1OFFirstPoint;
    doseInitS(i).coord2OFFirstPoint     = tags.coord2OFFirstPoint;
    doseInitS(i).transferProtocol       ='DICOM';


    % it would be possible to retrive this info from the RTDOSE images info
    % however for consistency we get xmesh ymesh and zmesh already calculated
    doseInitS(i).horizontalGridInterval = tags.horizontalGridInterval;
    doseInitS(i).verticalGridInterval   = tags.verticalGridInterval;
    % Optional
    doseInitS(i).numberOfTx             = 1;                % ALWAYS ONE. DICOM-RT DOSE IS TOTAL DOSE
    doseInitS(i).doseDescription        = '';               % LEAVE FOR NOW
    doseInitS(i).doseEdition            = '';               % LEAVE FOR NOW
    doseInitS(i).unitNumber             = '';               % LEAVE FOR NOW
    try
        doseInitS(i).writer                 = info_image.OperatorName.FamilyName;
    catch
        doseInitS(i).writer                 = '';
    end
    try
        doseInitS(i).dateWritten            = info_image.InstanceCreationDate;
    catch
        doseInitS(i).dateWritten            = '';
    end
    doseInitS(i).planNumberOfOrigin     = '';               % LEAVE FOR NOW
    doseInitS(i).planEditionOfOrigin    = '';               % LEAVE FOR NOW
    doseInitS(i).studyNumberOfOrigin    = '';               % LEAVE FOR NOW
    doseInitS(i).versionNumberOfProgram = '';               % LEAVE FOR NOW
    doseInitS(i).xcoordOfNormaliznPoint = '';               % LEAVE TO dicomrt_d2c_coordsystem
    doseInitS(i).ycoordOfNormaliznPoint = '';               % LEAVE TO dicomrt_d2c_coordsystem
    doseInitS(i).zcoordOfNormaliznPoint = '';               % LEAVE TO dicomrt_d2c_coordsystem
    %doseInitS(i).xcoordOfNormaliznPoint = info_image.DoseReferenceSequence.Item_1.DoseReferencePointCoordinates(1).*0.1;
    %doseInitS(1).ycoordOfNormaliznPoint = info_image.DoseReferenceSequence.Item_1.DoseReferencePointCoordinates(2).*0.1;
    %doseInitS(1).zcoordOfNormaliznPoint = info_image.DoseReferenceSequence.Item_1.DoseReferencePointCoordinates(3).*0.1;
    try
        doseInitS(i).doseAtNormaliznPoint   = info_image.DoseReferenceSequence.Item_1.TargetPrescriptionDose;
    catch
        doseInitS(i).doseAtNormaliznPoint   ='';
    end
    doseInitS(i).doseError              = '';               % LEAVE FOR NOW
    doseInitS(i).coord3OfFirstPoint     = '';               % LEAVE FOR NOW
    doseInitS(i).depthGridInterval      = '';               % LEAVE FOR NOW

    doseInitS(i).doseArray              = doseImage;
    doseInitS(i).zValues                = zmesh';
    doseInitS(i).delivered              = '';               % LEAVE FOR NOW
    doseInitS(i).doseUID                = createUID('DOSE');
    doseInitS(i).assocScanUID           = scanUID;
end

planC{indexS.dose} = doseInitS;

save_planC(planC,'','saveas');

clear planC;