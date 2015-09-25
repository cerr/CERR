function [tmpS study] = dicomrt_d2c_SPECT(SPECTInitS,study)
% dicomrt_d2c_SPECT(SPECTInitS,study)
%
% converts the passed PET Cell to CERR structure.
% SPECTInitS is the initialized CERR structure representing PET scan.
%
% study is the actual PET Cell with following structure
%         PETCell{1} = PET_Scan_Info;
%         PETCell{2} = PET_Scan;
%         PETCell{3} = xVec;
%         PETCell{4} = yVec;
%         PETCell{5} = sort(ZSlice);
%
% Created DK

tmpS.scanArray            = study{2};
tmpS.scanType             = 'NM';
tmpS.scanInfo             = SPECTInitS;
tmpS.uniformScanInfo      = '';
tmpS.scanArraySuperior    = '';
tmpS.scanArrayInferior    = '';
tmpS.scanUID              = createUID('SCAN');

[tags study]=dicomrt_d2c_SPECTcoordsystem(study);

type = 'NM';
info = study{1};
xmesh = study{3};
ymesh = study{4};
zmesh = study{5};
% Scan info
for i=1:length(study{5}) % loop through the number of slices
    % it would be possible to retrive dimensions from the CT images info
    % however for consistency we get ct_xmesh ct_ymesh and ct_zmesh already calculated

    % Fill SPECTInitS
    SPECTInitS(i).imageNumber            = i;
    SPECTInitS(i).imageType              = type;   
    SPECTInitS(i).patientName            = [info.PatientName.FamilyName];
    try
        SPECTInitS(i).patientName            = [SPECTInitS(i).patientName,' ', ...
            info.PatientName.GivenName]; % may be not present in anonymized studies
    end
    SPECTInitS(i).scanType               = info.ImageType;
    SPECTInitS(i).grid1Units             = tags.grid1Units;
    SPECTInitS(i).grid2Units             = tags.grid2Units;
    SPECTInitS(i).numberRepresentation   = 'TWO''S COMPLEMENT INTEGER';                 % LEAVE FOR NOW
    SPECTInitS(i).bytesPerPixel          = 2;                                           % LEAVE FOR NOW
    SPECTInitS(i).numberOfDimensions     = length(info.PixelSpacing);
    SPECTInitS(i).sizeOfDimension1       = double(info.Rows);
    SPECTInitS(i).sizeOfDimension2       = double(info.Columns);
    SPECTInitS(i).zValue                 = zmesh(i);
    SPECTInitS(i).xOffset                = tags.xOffset;
    SPECTInitS(i).yOffset                = tags.yOffset;
    SPECTInitS(i).CTOffset               = 0;
    SPECTInitS(i).sliceThickness         = info.SliceThickness.*0.1;
    try
        SPECTInitS(i).siteOfInterest         = info.StudyDescription;
    catch
        SPECTInitS(i).siteOfInterest         = info.StudyID;
    end

    try
        SPECTInitS(i).scanDescription        = info.StudyDescription;
    catch
        SPECTInitS(i).scanDescription        = info.StudyID;
    end
    
    SPECTInitS(i).scannerType            = info.Manufacturer;
    SPECTInitS(i).scanFileName           = info.Filename;
    try
        SPECTInitS(i).headInOut              = tags.hio;
    end
    try
        SPECTInitS(i).positionInScan         = tags.pos;
    end
    
    SPECTInitS(i).scanNumber             = info.InstanceNumber;
    
    try
        SPECTInitS(i).scanDate           = info.ImageDate;
    catch
        SPECTInitS(i).scanDate           ='';
    end
    SPECTInitS(i).transferProtocol       = 'DICOM';
    SPECTInitS(i).DICOMHeaders           = info;
    try
        SPECTInitS(i).PatientAge               = info.PatientAge;
    end
    try
        SPECTInitS(i).PatientWeight            = info.PatientWeight;
    end
  
    SPECTInitS(i).RadiopharmaceuticalInformationSequence  = info.RadiopharmaceuticalInformationSequence;
    SPECTInitS(i).PatientOrientationCodeSequence          = info.PatientOrientationCodeSequence ;
    SPECTInitS(i).PatientGantryRelationshipCodeSequence   = info.PatientGantryRelationshipCodeSequence;
end

% Update nimages
tags.nimages = size(info,2); % number of PET images

% Writing CERR scan data
tmpS.scanInfo             = SPECTInitS;