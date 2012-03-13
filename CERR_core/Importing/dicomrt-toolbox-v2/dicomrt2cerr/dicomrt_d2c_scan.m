function [tmpS,tags] = dicomrt_d2c_scan(scanInitS,indexS,study,xmesh,ymesh,zmesh,tags)
% dicomrt_d2c_scan(scanInitS,indexS,study,xmesh,ymesh,zmesh,tags)
%
% Convert DICOM scan data in CERR format
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org)

% Check input data
[study,type,dummylabel,PatientPosition]=dicomrt_checkinput(study);

if strcmpi('CT',type)~=1
    error('dicomrt_d2c_scan: input data does not have the right format. Exit now!');
else
    type='CT SCAN';
end

% Set Patient Position in rtogtags for further use
tags.dicomPatientPosition = PatientPosition;

% Accounting for different coordinate system between DICOM and RTOG
[study,xmesh,ymesh,zmesh,tags]=dicomrt_d2c_coordsystem(study,xmesh,ymesh,zmesh,tags);

% Get DICOM-RT toolbox dataset info
study_pointer=study{1,1};
temp_study_header=study_pointer{1};
study_array=study{2,1};

% Construct the scan structure
tmpS = dicomrt_d2c_buildscanstr(scanInitS);

% Accounting for uint16 CERR format storage option
if strcmpi(class(study_array),'uint16')==0
    study_array=uint16(study_array - 1);
end

% Scan info
for i=1:size(study_pointer,2); % loop through the number of slices
    % it would be possible to retrive dimensions from the CT images info
    % however for consistency we get ct_xmesh ct_ymesh and ct_zmesh already calculated

    % Fill ScanInitS
    scanInitS(i).imageNumber            = i;
    scanInitS(i).imageType              = type;
    scanInitS(i).caseNumber             = 1;                                           % LEAVE FOR NOW
    scanInitS(i).patientName            = [study_pointer{i}.PatientName.FamilyName];
    try
        scanInitS(i).patientName            = [scanInitS(i).patientName,' ', ...
            study_pointer{i}.PatientName.GivenName]; % may be not present in anonymized studies
    end
    scanInitS(i).scanType               = study_pointer{i}.ImageType;
    %scanInitS(i).CTOffset               = -study_pointer{i}.RescaleIntercept;
    scanInitS(i).CTOffset               = 1000;
    scanInitS(i).grid1Units             = tags.grid1Units;
    scanInitS(i).grid2Units             = tags.grid2Units;
    scanInitS(i).numberRepresentation   = 'TWO''S COMPLEMENT INTEGER';                 % LEAVE FOR NOW
    scanInitS(i).bytesPerPixel          = 2;                                           % LEAVE FOR NOW
    scanInitS(i).numberOfDimensions     = length(study_pointer{i}.PixelSpacing);
    scanInitS(i).sizeOfDimension1       = double(study_pointer{i}.Rows);
    scanInitS(i).sizeOfDimension2       = double(study_pointer{i}.Columns);
    scanInitS(i).zValue                 = zmesh(i);
    scanInitS(i).xOffset                = tags.xOffset;
    scanInitS(i).yOffset                = tags.yOffset;
    scanInitS(i).CTAir                  = 0;                                                % LEAVE FOR NOW
    scanInitS(i).CTWater                = 1000;                                             % LEAVE FOR NOW
    scanInitS(i).sliceThickness         = study_pointer{i}.SliceThickness.*0.1;
    try
        scanInitS(i).siteOfInterest         = study_pointer{i}.StudyDescription;
    catch
        scanInitS(i).siteOfInterest         = study_pointer{i}.StudyID;
    end
    try
        scanInitS(i).unitNumber             = study_pointer{i}.StationName;
    catch
        try
            scanInitS(i).unitNumber             = study_pointer{i}.ManufacturerModelName;
        catch
            scanInitS(i).unitNumber             = [];
        end
    end
    try
        scanInitS(i).scanDescription        = study_pointer{i}.StudyDescription;
    catch
        scanInitS(i).scanDescription        = study_pointer{i}.StudyID;
    end
    scanInitS(i).scannerType            = study_pointer{i}.Manufacturer;
    scanInitS(i).scanFileName           = study_pointer{i}.Filename;
    scanInitS(i).headInOut              = tags.hio;
    scanInitS(i).positionInScan         = tags.pos;
    scanInitS(i).patientAttitude        ='';                                                % LEAVE FOR NOW
    scanInitS(i).tapeOfOrigin           ='';                                                % LEAVE FOR NOW
    scanInitS(i).studyNumberOfOrigin    ='';                                                % LEAVE FOR NOW
    try
        scanInitS(i).scanID                 = study_pointer{i}.StudyID;
    catch
        scanInitS(i).scanID                 = 'UNKNOWN';
        % may be not present in anonymized studies
    end
    scanInitS(i).scanNumber             = study_pointer{i}.InstanceNumber;
    try
        scanInitS(i).scanDate           = study_pointer{i}.ImageDate;
    catch
        scanInitS(i).scanDate           ='';
    end
    scanInitS(i).CTScale                ='';                                                % LEAVE FOR NOW
    scanInitS(i).distrustAbove          ='';                                                % LEAVE FOR NOW
    scanInitS(i).imageSource            = study_pointer{i}.ImageType;
    scanInitS(i).transferProtocol       = 'DICOM';
    scanInitS(i).DICOMHeaders           = study_pointer{i};
end

% Update nimages
tags.nimages = tags.nimages + size(study_pointer,2); % number of CT images

% Writing CERR scan data
tmpS.scanArray=study_array;
tmpS.scanType=temp_study_header.Modality;
tmpS.scanInfo = scanInitS;
tmpS.scanUID = createUID('SCAN');
