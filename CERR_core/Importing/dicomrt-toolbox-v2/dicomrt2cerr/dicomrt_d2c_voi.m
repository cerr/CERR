function [structureInitS,tags] = dicomrt_d2c_voi(structureInitS,indexS,voi,xmesh,ymesh,zmesh,tags,scanUID)
% dicomrt_d2c_voi(structureInitS,indexS,voi,ct_zmesh)
%
% Convert DICOM VOI in CERR format
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org)

% Check input data
[study,type,dummylabel]=dicomrt_checkinput(voi);

if strcmpi('VOI',type)~=1
    error('dicomrt_d2c_voi: input data does not have the right format. Exit now!');
else
    type='STRUCTURE';
end

% Accounting for different coordinate system between DICOM and RTOG
[study,xmesh,ymesh,zmesh,tags]=dicomrt_d2c_coordsystem(study,xmesh,ymesh,zmesh,tags);

% Get DICOM-RT toolbox dataset info
study_pointer=study{1,1};
study_array=study{2,1};

% Set parameters
n = indexS.scan;

% Scan info
for i=1:size(study_array,1); % loop through the number of VOIs
    % Fill structureInitS
    structureInitS(i).imageNumber            = tags.nimages + i;
    structureInitS(i).imageType              = type;
    structureInitS(i).caseNumber             = 1;                                         % LEAVE FOR NOW
    structureInitS(i).patientName            = [study_pointer.PatientName.FamilyName];
    try
        structureInitS(i).patientName        = [structureInitS(i).patientName,' ', ...
            study_pointer.PatientName.GivenName]; % may be not present in anonymized studies
    end
    structureInitS(i).structureName          = study_array{i,1};
    structureInitS(i).numberRepresentation   = 'CHARACTER';
    structureInitS(i).structureFormat        = 'SCAN-BASED';
    structureInitS(i).numberOfScans          = tags.nimages;
    structureInitS(i).transferProtocol       = 'DICOM';
    structureInitS(i).DICOMHeaders           = study_pointer;
    % Optional
    structureInitS(i).maximumNumberScans     = '';
    structureInitS(i).structureEdition       = '';
    structureInitS(i).unitNumber             = '';
    structureInitS(i).writer                 = '';
    structureInitS(i).dateWritten            = '';
    structureInitS(i).structureColor         = '';
    structureInitS(i).structureDescription   = '';
    structureInitS(i).studyNumberOfOrigin    = '';
    % build vector containing Z location of VOIs
    [voizdef,index] = dicomrt_getvoiz(study,i);
    for j=1:tags.nimages % loop through CT scans
        % locate position of VOI segment
        locate_voi=find(voizdef==zmesh(j));
        if isempty(locate_voi)==1
            structureInitS(i).contour(length(zmesh)-j+1).segments.points=[];
        else
            for jj=1:length(locate_voi)
                if ~isempty(study_array{i,2})% check for empty structures
                    structureInitS(i).contour(length(zmesh)-j+1).segments(jj).points=study_array{i,2}{index(locate_voi(jj))};
                else
                    structureInitS(i).contour(length(zmesh)-j+1).segments(jj).points=[];
                end
            end
        end
    end
    clear voizdef;
    structureInitS(i).rasterSegments         = '';
    structureInitS(i).DSHPoints              = '';
    structureInitS(i).orientationOfStructure = '';

    %DK
    structureInitS(i).strUID = createUID('STRUCTURE');
    if exist('scanUID')
        structureInitS(i).assocScanUID = scanUID;
    else
        structureInitS(i).assocScanUID = '';
    end
    %end DK
end

% Update nimages
tags.nimages = tags.nimages + size(study_array,1); % number of CT images
