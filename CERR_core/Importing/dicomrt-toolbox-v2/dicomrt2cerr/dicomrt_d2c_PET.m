function [tmpS study] = dicomrt_d2c_PET(PETInitS,study)
% [tmpS study] = dicomrt_d2c_PETscan(PETInitS,indexS,study)
%
% converts the passed PET Cell to CERR structure.
% PETInitS is the initialized CERR structure representing PET scan.
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
tmpS.scanType             = 'PET';
tmpS.scanInfo             = PETInitS;
tmpS.uniformScanInfo      = '';
tmpS.scanArraySuperior    = '';
tmpS.scanArrayInferior    = '';
tmpS.scanUID              = createUID('SCAN');

[tags study]=dicomrt_d2c_PETcoordsystem(study);

info = study{1};
xmesh = study{3};
ymesh = study{4};
zmesh = study{5};
% Scan info
for i=1:size(study{1},2); % loop through the number of slices
    % it would be possible to retrive dimensions from the CT images info
    % however for consistency we get ct_xmesh ct_ymesh and ct_zmesh already calculated

    % Fill PETInitS
    PETInitS(i).imageNumber            = i;
    PETInitS(i).imageType              = 'PET';  
    PETInitS(i).patientName            = [info{i}.PatientName.FamilyName];
    try
        PETInitS(i).patientName            = [PETInitS(i).patientName,' ', ...
            info{i}.PatientName.GivenName]; % may be not present in anonymized studies
    end
    PETInitS(i).scanType               = info{i}.ImageType;
    PETInitS(i).grid1Units             = tags.grid1Units;
    PETInitS(i).grid2Units             = tags.grid2Units;
    PETInitS(i).numberRepresentation   = 'TWO''S COMPLEMENT INTEGER';                 % LEAVE FOR NOW
    PETInitS(i).bytesPerPixel          = 2;                                           % LEAVE FOR NOW
    PETInitS(i).numberOfDimensions     = length(info{i}.PixelSpacing);
    PETInitS(i).sizeOfDimension1       = double(info{i}.Rows);
    PETInitS(i).sizeOfDimension2       = double(info{i}.Columns);
    PETInitS(i).zValue                 = zmesh(i);
    PETInitS(i).xOffset                = tags.xOffset;
    PETInitS(i).yOffset                = tags.yOffset;

    PETInitS(i).sliceThickness         = info{i}.SliceThickness.*0.1;
    try
        PETInitS(i).siteOfInterest         = info{i}.StudyDescription;
    catch
        PETInitS(i).siteOfInterest         = info{i}.StudyID;
    end

    try
        PETInitS(i).scanDescription        = info{i}.StudyDescription;
    catch
        PETInitS(i).scanDescription        = info{i}.StudyID;
    end
    
    PETInitS(i).scannerType            = info{i}.Manufacturer;
    PETInitS(i).scanFileName           = info{i}.Filename;
    try
        PETInitS(i).headInOut              = tags.hio;
    end
    try
        PETInitS(i).positionInScan         = tags.pos;
    end
    
    PETInitS(i).scanNumber             = info{i}.InstanceNumber;
    
    try
        PETInitS(i).scanDate           = info{i}.ImageDate;
    catch
        PETInitS(i).scanDate           ='';
    end
    PETInitS(i).transferProtocol       = 'DICOM';
    PETInitS(i).DICOMHeaders           = info{i};
    
    try
    PETInitS(i).PatientAge               = info{i}.PatientAge;
    end

    try
        PETInitS(i).PatientWeight            = info{i}.PatientWeight;
    end

    PETInitS(i).RescaleIntercept         = info{i}.RescaleIntercept;
    PETInitS(i).RescaleSlope             = info{i}.RescaleSlope;
    
    try
        PETInitS(i).RescaleType                 = info{i}.RescaleType;
    end

    try
        PETInitS(i).EnergyWindowRangeSequence   = info{i}.EnergyWindowRangeSequence;
    end

    PETInitS(i).RadiopharmaceuticalInformationSequence  = info{i}.RadiopharmaceuticalInformationSequence;
    PETInitS(i).PatientOrientationCodeSequence          = info{i}.PatientOrientationCodeSequence ;
    PETInitS(i).PatientGantryRelationshipCodeSequence   = info{i}.PatientGantryRelationshipCodeSequence;
    
    try
        PETInitS(i).AxialAcceptance             = info{i}.AxialAcceptance;
    end

    try
        PETInitS(i).AxialMash                   = info{i}.AxialMash;
    end

    PETInitS(i).FrameReferenceTime          = info{i}.FrameReferenceTime;
    
    try
        PETInitS(i).DecayFactor                 = info{i}.DecayFactor;
    end

    PETInitS(i).DecayCorrection                 = info{i}.DecayCorrection;
    
    try
        PETInitS(i).DoseCalibrationFactor       = info{i}.DoseCalibrationFactor;
    end
end

% Update nimages
tags.nimages = size(info,2); % number of PET images

% Writing CERR scan data
tmpS.scanInfo             = PETInitS;