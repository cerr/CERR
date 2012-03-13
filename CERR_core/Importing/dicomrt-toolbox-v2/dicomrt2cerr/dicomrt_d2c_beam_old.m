function [beamGeometryInitS,tags] = dicomrt_d2c_beam(beamGeometryInitS,indexS,study,tags)
% dicomrt_d2c_beam(beamGeometryInitS,indexS,plan,tags)
%
% Convert DICOM beam data in CERR format.
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check input data
[study,type,dummylabel,PatientPosition]=dicomrt_checkinput(study);

if strcmpi('RTPLAN',type)~=1
    error('dicomrt_d2c_scan: input data does not have the right format. Exit now!');
else
    type='BEAM GEOMETRY';
end

% Get DICOM-RT toolbox dataset info
study_pointer=study{1,1};
temp_study_header=study_pointer{1};

% Get parameters
beams=fieldnames(temp_study_header.BeamSequence);
nbeams=size(beams,1);

for i=1:nbeams; % loop through the number of slices
    beamGeometryInitS(i).imageNumber                = tags.nimages +i;
    beamGeometryInitS(i).imageType                  = type;
    beamGeometryInitS(i).caseNumber                 = 1;
    beamGeometryInitS(i).patientName                = [temp_study_header.PatientName.FamilyName ,' ', ...
                temp_study_header.PatientName.GivenName];
    beamGeometryInitS(i).beamNumber                 = getfield(temp_study_header,'BeamSequence',char(beams(i)),...
        'BeamNumber');
    % RadiationType
    RadiationType=getfield(temp_study_header,'BeamSequence',char(beams(i)),'RadiationType');
    if strcmpi(RadiationType,'PHOTON')==1
        beamGeometryInitS(i).beamModality               = 'X-RAY';
    else % 'OTHER' is not a possibility
        beamGeometryInitS(i).beamModality               = RadiationType;
    end
    beamGeometryInitS(i).beamEnergyMeV              = getfield(temp_study_header,'BeamSequence',char(beams(i)),...
        'ControlPointSequence','Item_1','NominalBeamEnergy');
    beamGeometryInitS(i).beamDescription            = getfield(temp_study_header,'BeamSequence',char(beams(i)),...
        'BeamName');
    beamGeometryInitS(i).RxDosePerTxGy              = getfield(temp_study_header,'FractionGroupSequence','Item_1',...
        'ReferencedBeamSequence',char(beams(i)),'BeamDose');
    beamGeometryInitS(i).numberOfTx                 = getfield(temp_study_header,'FractionGroupSequence','Item_1',...
        'NumberOfFractionsPlanned');
    
    beamGeometryInitS(i).fractionGroupID            = temp_study_header.RTPlanDescription;
    beamGeometryInitS(i).beamType                   = getfield(temp_study_header,'BeamSequence',char(beams(i)),...
        'BeamType');
    beamGeometryInitS(i).planIDOfOrigin             = temp_study_header.StudyID;
    % collimatorType
    xjaw = getfield(temp_study_header,'BeamSequence',char(beams(i)),'ControlPointSequence','Item_1',...
        'BeamLimitingDevicePositionSequence','Item_1','LeafJawPositions');
    yjaw =  getfield(temp_study_header,'BeamSequence',char(beams(i)),'ControlPointSequence','Item_1',...
        'BeamLimitingDevicePositionSequence','Item_2','LeafJawPositions');
    if -xjaw(1)==xjaw(2) & -yjaw(1)==yjaw(2)
        beamGeometryInitS(i).collimatorType             = 'SYMMETRIC';
    elseif -xjaw(1)==xjaw(2) & -yjaw(1)~=yjaw(2)
        beamGeometryInitS(i).collimatorType             = 'ASYMMETRIC_Y';
    elseif -xjaw(1)==xjaw(2) & -yjaw(1)~=yjaw(2)
        beamGeometryInitS(i).collimatorType             = 'ASYMMETRIC_X';
    else
        beamGeometryInitS(i).collimatorType             = 'ASYMMETRIC';
    end
    % apertureType
    % set default
    nblocks = 0;
    ncomp   = 0;
    mlcmod  = 0;
    nwedges = 0;
    % retrieve info
    nblocks = getfield(temp_study_header,'BeamSequence',char(beams(i)),'NumberOfBlocks');
    ncomp   = getfield(temp_study_header,'BeamSequence',char(beams(i)),'NumberOfCompensators');
    mlcmod  = 0;
    nwedges = getfield(temp_study_header,'BeamSequence',char(beams(i)),'NumberOfWedges');
    % check
    if nblocks ~= 0
        beamGeometryInitS(i).apertureType               = 'BLOCKS';
    elseif ncomp ~= 0
        beamGeometryInitS(i).apertureType               = 'TRANSMISSION_MAP';
    elseif mlcmod ~= 0
        beamGeometryInitS(i).apertureType               = 'MLC_XY';
    else
        beamGeometryInitS(i).apertureType               = 'COLLIMATOR';
    end
    beamGeometryInitS(i).apertureDescription        = getfield(temp_study_header,'BeamSequence',char(beams(i)),...
        'BeamName');
    beamGeometryInitS(i).collimatorAngle            = getfield(temp_study_header,'BeamSequence',char(beams(i)),...
        'ControlPointSequence','Item_1','BeamLimitingDeviceAngle');
    beamGeometryInitS(i).gantryAngle                = 360-getfield(temp_study_header,'BeamSequence',char(beams(i)),...
        'ControlPointSequence','Item_1','GantryAngle');
    beamGeometryInitS(i).couchAngle                 = getfield(temp_study_header,'BeamSequence',char(beams(i)),...
        'ControlPointSequence','Item_1','TableTopEccentricAngle');
    beamGeometryInitS(i).headInOut                  = tags.hio;
    beamGeometryInitS(i).nominalIsocenterDistance   = getfield(temp_study_header,'BeamSequence',char(beams(i)),...
        'SourceAxisDistance').*0.1;
    beamGeometryInitS(i).numberRepresentation       = 'CHARACTER';
    % Optional
    beamGeometryInitS(i).apertureID                 = '';
    if nwedges ~= 0
        beamGeometryInitS(i).wedgeAngle                 = getfield(temp_study_header,'BeamSequence',char(beams(i)),...
            'WedgeSequence','Item_1','WedgeAngle');
        beamGeometryInitS(i).wedgeRotationAngle         = 360-getfield(temp_study_header,'BeamSequence',char(beams(i)),...
            'WedgeSequence','Item_1','WedgeOrientation');
    else
        beamGeometryInitS(i).wedgeAngle                 = '';
        beamGeometryInitS(i).wedgeRotationAngle         = '';
    end
    beamGeometryInitS(i).arcAngle                   = '';
    beamGeometryInitS(i).machineID                  = getfield(temp_study_header,'BeamSequence',char(beams(i)),...
        'TreatmentMachineName');
    beamGeometryInitS(i).beamWeight                 = '';
    beamGeometryInitS(i).weightUnits                = '';
    beamGeometryInitS(i).compensator                = '';
    beamGeometryInitS(i).compensatorFormat          = '';
    beamGeometryInitS(i).file                       = '';
end

% Update nimages
tags.nimages = tags.nimages + nbeams; 
