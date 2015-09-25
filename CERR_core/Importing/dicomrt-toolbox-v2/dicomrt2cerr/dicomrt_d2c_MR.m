function [tmpS study] = dicomrt_d2c_MR(MRInitS,study);

tmpS.scanArray            = study{2};
tmpS.scanType             = 'MR';
tmpS.scanInfo             = MRInitS;
tmpS.uniformScanInfo      = '';
tmpS.scanArraySuperior    = '';
tmpS.scanArrayInferior    = '';

[tags study]=dicomrt_d2c_PETcoordsystem(study);

type = 'MR';
info = study{1};
xmesh = study{3};
ymesh = study{4};
zmesh = study{5};
% Scan info

for i=1:size(study{1},2); % loop through the number of slices
    % it would be possible to retrive dimensions from the CT images info
    % however for consistency we get ct_xmesh ct_ymesh and ct_zmesh already calculated

    % Fill MRInitS
    MRInitS(i).imageNumber            = i;
    MRInitS(i).imageType              = type;
    MRInitS(i).caseNumber             = 1;                                           % LEAVE FOR NOW
    MRInitS(i).patientName            = [info{i}.PatientName.FamilyName];
    try
        MRInitS(i).patientName            = [MRInitS(i).patientName,' ', ...
            info{i}.PatientName.GivenName]; % may be not present in anonymized studies
    end
    MRInitS(i).scanType               = info{i}.ImageType;
    MRInitS(i).CTOffset               = 1000;
    MRInitS(i).grid1Units             = tags.grid1Units;
    MRInitS(i).grid2Units             = tags.grid2Units;
    MRInitS(i).numberRepresentation   = 'TWO''S COMPLEMENT INTEGER';                 % LEAVE FOR NOW
    MRInitS(i).bytesPerPixel          = 2;                                           % LEAVE FOR NOW
    MRInitS(i).numberOfDimensions     = length(info{i}.PixelSpacing);
    MRInitS(i).sizeOfDimension1       = double(info{i}.Rows);
    MRInitS(i).sizeOfDimension2       = double(info{i}.Columns);
    MRInitS(i).zValue                 = zmesh(i);
    MRInitS(i).xOffset                = tags.xOffset;
    MRInitS(i).yOffset                = tags.yOffset;
    MRInitS(i).CTAir                  = 0;                                                % LEAVE FOR NOW
    MRInitS(i).CTWater                = 1000;                                             % LEAVE FOR NOW
    MRInitS(i).sliceThickness         = info{i}.SliceThickness.*0.1;
    try
        try
            MRInitS(i).siteOfInterest         = info{i}.StudyDescription;
        catch
            MRInitS(i).siteOfInterest         = info{i}.StudyID;
        end
        try
            MRInitS(i).unitNumber             = info{i}.StationName;
        catch
            MRInitS(i).unitNumber             = info{i}.ManufacturerModelName;
        end
        try
            MRInitS(i).scanDescription        = info{i}.StudyDescription;
        catch
            MRInitS(i).scanDescription        = info{i}.StudyID;
        end
        MRInitS(i).scannerType            = info{i}.Manufacturer;
        MRInitS(i).scanFileName           = info{i}.Filename;
        try
            MRInitS(i).headInOut              = tags.hio;
        end
        try
            MRInitS(i).positionInScan         = tags.pos;
        end
        MRInitS(i).patientAttitude        ='';                                                % LEAVE FOR NOW
        MRInitS(i).tapeOfOrigin           ='';                                                % LEAVE FOR NOW
        MRInitS(i).studyNumberOfOrigin    ='';                                                % LEAVE FOR NOW
        try
            MRInitS(i).scanID                 = info{i}.StudyID;
        catch
            MRInitS(i).scanID                 = 'UNKNOWN';
            % may be not present in anonymized studies
        end
        MRInitS(i).scanNumber             = info{i}.InstanceNumber;
        try
            MRInitS(i).scanDate           = info{i}.ImageDate;
        catch
            MRInitS(i).scanDate           ='';
        end

    catch
        % Do nothing
    end



    MRInitS(i).CTScale                ='';                                                % LEAVE FOR NOW
    MRInitS(i).distrustAbove          ='';                                                % LEAVE FOR NOW
    MRInitS(i).imageSource            = info{i}.ImageType;
    MRInitS(i).transferProtocol       = 'DICOM';
    MRInitS(i).DICOMHeaders           = info{i};
    try
        MRInitS(i).PatientAge             = info{i}.PatientAge;
    end
    try
        MRInitS(i).PatientWeight          = info{i}.PatientWeight;
    end
    try
        MRInitS(i).MRAcquisitionType      = info{i}.MRAcquisitionType;
    end
    try
        MRInitS(i).SequenceName           = info{i}.SequenceName;
    end
    try
        MRInitS(i).RepetitionTime         = info{i}.RepetitionTime;
    end
    try
        MRInitS(i).EchoTime               = info{i}.EchoTime;
    end
    try
        MRInitS(i).NumberOfAverages       = info{i}.NumberOfAverages;
    end
    try
        MRInitS(i).ImagingFrequency       = info{i}.ImagingFrequency;
    end
    try
        MRInitS(i).ImagedNucleus          = info{i}.ImagedNucleus;
    end
    try
        MRInitS(i).EchoNumber             = info{i}.EchoNumber;
    end
    try
        MRInitS(i).MagneticFieldStrength  = info{i}.MagneticFieldStrength;
    end
    try
        MRInitS(i).ProtocolName           = info{i}.ProtocolName;
    end
    try
        MRInitS(i).VariableFlipAngleFlag  = info{i}.VariableFlipAngleFlag;
    end
    try
        MRInitS(i).NumberOfPhaseEncodingSteps   = info{i}.NumberOfPhaseEncodingSteps;
    end
    try
        MRInitS(i).EchoTrainLength        = info{i}.EchoTrainLength;
    end
    try
        MRInitS(i).PercentSampling        = info{i}.PercentSampling;
    end
    try
        MRInitS(i).PercentPhaseFieldOfView= info{i}.PercentPhaseFieldOfView;
    end
    try
        MRInitS(i).PixelBandwidth         = info{i}.PixelBandwidth;
    end
    try
        MRInitS(i).AcquisitionMatrix      = info{i}.AcquisitionMatrix;
    end
    try
        MRInitS(i).TransmitCoilName       = info{i}.TransmitCoilName;
    end
    try
        MRInitS(i).InPlanePhaseEncodingDirection = info{i}.InPlanePhaseEncodingDirection;
    end
    try
        MRInitS(i).FlipAngle               = info{i}.FlipAngle;
    end
    try
        MRInitS(i).SAR                     = info{i}.SAR ;
    end
    try
        MRInitS(i).dBdt                    = info{i}.dBdt ;
    end
end

% Update nimages
tags.nimages = size(info,2); % number of CT images

% Writing CERR scan data
% tmpS.scanArray=study_array;
% tmpS.scanType=temp_study_header.Modality;________initialized @ begining
tmpS.scanInfo = MRInitS;