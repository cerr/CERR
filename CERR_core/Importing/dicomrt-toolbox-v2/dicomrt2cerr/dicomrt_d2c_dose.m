function [tmpS,tags] = dicomrt_d2c_dose(doseInitS,indexS,study,xmesh,ymesh,zmesh,tags,scanUID)
% dicomrt_d2c_dose(doseInitS,indexS,study,xmesh,ymesh,zmesh,tags)
%
% Convert DICOM dose data in CERR format
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check input data
[study,type,dummylabel,PatientPosition]=dicomrt_checkinput(study);

if strcmpi('RTPLAN',type)~=1
    error('dicomrt_d2c_scan: input data does not have the right format. Exit now!');
else
    type='DOSE';
end

% Accounting for different coordinate system between DICOM and RTOG
[study,xmesh,ymesh,zmesh,tags]=dicomrt_d2c_coordsystem(study,xmesh,ymesh,zmesh,tags);

% Get DICOM-RT toolbox dataset info
study_pointer=study{1,1};
temp_study_header=study_pointer{1};
study_array=study{2,1};

% Dose info
% Fill doseInitS
doseInitS(1).imageNumber            = tags.nimages + 1;
doseInitS(1).imageType              = type;
doseInitS(1).caseNumber             = 1;               % ALWAYS ONE. DICOM-RT DOSE IS TOTAL DOSE
doseInitS(1).patientName            = [study_pointer{1}.PatientName.FamilyName];
try
    doseInitS(i).patientName     = [doseInitS(i).patientName,' ', ...
            study_pointer{1}.PatientName.GivenName]; % may be not present in anonymized studies 
end
doseInitS(1).doseNumber             = 1;               % ALWAYS ONE. DICOM-RT DOSE IS TOTAL DOSE
doseInitS(1).doseType               = study_pointer{2}.DoseType;
doseInitS(1).doseUnits              = study_pointer{2}.DoseUnits;
doseInitS(1).doseScale              = 1;
try
    doseInitS(1).fractionGroupID        = study_pointer{1}.RTPlanDescription;
catch
    doseInitS(1).fractionGroupID        = study_pointer{1}.RTPlanLabel;
end
doseInitS(1).orientationOfDose      = 'TRANSVERSE';    % LEAVE FOR NOW
doseInitS(1).numberRepresentation   = 'CHARACTER';     % LEAVE FOR NOW
doseInitS(1).numberOfDimensions     = ndims(study_array);
doseInitS(1).sizeOfDimension1       = size(study_array,2);
doseInitS(1).sizeOfDimension2       = size(study_array,1);
doseInitS(1).sizeOfDimension3       = size(study_array,3);
doseInitS(1).coord1OFFirstPoint     = tags.coord1OFFirstPoint;
doseInitS(1).coord2OFFirstPoint     = tags.coord2OFFirstPoint;
doseInitS(1).transferProtocol       ='DICOM';
try
    doseInitS(1).DICOMHeaders           = study_pointer{2:end};
catch
    doseInitS(1).DICOMHeaders           = study_pointer(2:end);
end

% it would be possible to retrive this info from the RTDOSE images info
% however for consistency we get xmesh ymesh and zmesh already calculated
doseInitS(1).horizontalGridInterval = tags.horizontalGridInterval;
doseInitS(1).verticalGridInterval   = tags.verticalGridInterval;
% Optional
doseInitS(1).numberOfTx             = 1;                % ALWAYS ONE. DICOM-RT DOSE IS TOTAL DOSE
doseInitS(1).doseDescription        = '';               % LEAVE FOR NOW
doseInitS(1).doseEdition            = '';               % LEAVE FOR NOW
doseInitS(1).unitNumber             = '';               % LEAVE FOR NOW
try 
    doseInitS(1).writer                 = study_pointer{1}.OperatorName.FamilyName;
catch
    doseInitS(1).writer                 = '';
end
try
    doseInitS(1).dateWritten            = study_pointer{1}.InstanceCreationDate;
catch
    doseInitS(1).dateWritten            = '';
end
doseInitS(1).planNumberOfOrigin     = '';               % LEAVE FOR NOW
doseInitS(1).planEditionOfOrigin    = '';               % LEAVE FOR NOW
doseInitS(1).studyNumberOfOrigin    = '';               % LEAVE FOR NOW
doseInitS(1).versionNumberOfProgram = '';               % LEAVE FOR NOW
doseInitS(1).xcoordOfNormaliznPoint = '';               % LEAVE TO dicomrt_d2c_coordsystem
doseInitS(1).ycoordOfNormaliznPoint = '';               % LEAVE TO dicomrt_d2c_coordsystem
doseInitS(1).zcoordOfNormaliznPoint = '';               % LEAVE TO dicomrt_d2c_coordsystem
%doseInitS(1).xcoordOfNormaliznPoint = study_pointer{1}.DoseReferenceSequence.Item_1.DoseReferencePointCoordinates(1).*0.1;
%doseInitS(1).ycoordOfNormaliznPoint = study_pointer{1}.DoseReferenceSequence.Item_1.DoseReferencePointCoordinates(2).*0.1;
%doseInitS(1).zcoordOfNormaliznPoint = study_pointer{1}.DoseReferenceSequence.Item_1.DoseReferencePointCoordinates(3).*0.1;
try
    doseInitS(1).doseAtNormaliznPoint   = study_pointer{1}.DoseReferenceSequence.Item_1.TargetPrescriptionDose;
catch
    doseInitS(1).doseAtNormaliznPoint   ='';
end
doseInitS(1).doseError              = '';               % LEAVE FOR NOW
doseInitS(1).coord3OfFirstPoint     = '';               % LEAVE FOR NOW
doseInitS(1).depthGridInterval      = '';               % LEAVE FOR NOW
doseInitS(1).planIDOfOrigin         = study_pointer{1}.RTPlanLabel;
doseInitS(1).doseArray              = study_array;
doseInitS(1).zValues                = zmesh';
doseInitS(1).delivered              = '';               % LEAVE FOR NOW
doseInitS(1).doseUID                = createUID('DOSE');
doseInitS(1).assocScanUID           = scanUID;
% Writing CERR scan data
tmpS=doseInitS;

clear study xmesh ymesh zmesh study_pointer temp_study_header study_array