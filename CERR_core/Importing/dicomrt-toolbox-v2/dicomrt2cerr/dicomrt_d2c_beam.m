function [beamsInitS,beamGeometryInitS,tags] = dicomrt_d2c_beam(beamGeometryInitS,indexS,study,tags)
% dicomrt_d2c_beam(beamGeometryInitS,indexS,plan,tags)
%
% Convert DICOM beam data in CERR format.
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 
%
% 17 Dec 06  KU     Added beam geometry import (moved here from dicomrt_dicomrt2cerr).

global planC

% Check input data
[study,type,dummylabel,PatientPosition]=dicomrt_checkinput(study);

if strcmpi('RTPLAN',type)~=1
    disp(['dicomrt_d2c_scan: type is ', type]);
    error('dicomrt_d2c_scan: input data does not have the right format. Exit now!');
else
    type='BEAM GEOMETRY';
end

% Get DICOM-RT toolbox dataset info
study_pointer=study{1,1};
if isstruct(study_pointer)==1
    temp_study_header=study_pointer;
else
    temp_study_header=study_pointer{1};
end

beamsInitS = temp_study_header;

% Get parameters
try
    beams=fieldnames(temp_study_header.BeamSequence);
    nbeams=size(beams,1);
catch
    return
end

% Update nimages
tags.nimages = tags.nimages + nbeams; 

%----------------------------------------------------------------------------------------

%Convert beam geometry
%Fill beamGeometryInitS.
temp = beamGeometryInitS;
t2 = cell(1,nbeams);
[t2{:}] = deal(temp);
beamGeometryInitS = [t2{:}];

%get the beam parameters
for i=1:nbeams
    beamGeometryInitS(1,i).imageType            = type;
    try
        temp_value = [getfield(beamsInitS, 'PatientName', 'GivenName') ', ' getfield(beamsInitS, 'PatientName', 'FamilyName')];
        if ~isempty(temp_value)
            beamGeometryInitS(1,i).patientName  = temp_value;
        end
    end

      try
          beamGeometryInitS(1,i).fractionGroupID = beamsInitS.RTPlanLabel;
      catch              
          if ~isempty(planC{planC{end}.dose}) && isempty(planC{planC{end}.dose}(1,end).doseArray)
               beamGeometryInitS(1,i).fractionGroupID = num2str(length(planC{indexS.dose}));
          else
               beamGeometryInitS(1,i).fractionGroupID = num2str(length(planC{indexS.dose}))+1;
          end
      end

      beamGeometryInitS(1,i).beamNumber         = getfield(beamsInitS, 'BeamSequence',['Item_', num2str(i)],'BeamNumber');
      beamGeometryInitS(1,i).beamDescription    = getfield(beamsInitS, 'BeamSequence',['Item_', num2str(i)],'BeamName');
      beamGeometryInitS(1,i).beamModality       = getfield(beamsInitS, 'BeamSequence',['Item_', num2str(i)],'RadiationType');
      beamGeometryInitS(1,i).beamEnergyMeV      = getfield(beamsInitS, 'BeamSequence',['Item_',num2str(i)], 'ControlPointSequence','Item_1','NominalBeamEnergy');
      beamGeometryInitS(1,i).beamType           = getfield(beamsInitS, 'BeamSequence',['Item_', num2str(i)],'BeamType');
      beamGeometryInitS(1,i).nominalIsocenterDistance = getfield(beamsInitS, 'BeamSequence',['Item_', num2str(i)],'SourceAxisDistance');

      %get isocenter position               
      string = num2str((beamsInitS.BeamSequence.Item_1.ControlPointSequence.Item_1.IsocenterPosition)');
      beamGeometryInitS(1,i).file{1,1}          = ['"Isocenter coordinate" ' string];
      
      %get Collimator Setting X
      string = sprintf('%d, %d', eval(sprintf('beamsInitS.BeamSequence.%s.ControlPointSequence.Item_1.BeamLimitingDevicePositionSequence.Item_1.LeafJawPositions',beams{i})));
      beamGeometryInitS(1,i).file{1,2}          = ['"Collimator Setting X" ' string];
      %get collimator setting Y
      string = sprintf('%d, %d', eval(sprintf('beamsInitS.BeamSequence.%s.ControlPointSequence.Item_1.BeamLimitingDevicePositionSequence.Item_2.LeafJawPositions',beams{i})));
      beamGeometryInitS(1,i).file{1,3}          = ['"Collimator Setting Y" ' string];
      
      beamGeometryInitS(1,i).collimatorAngle    = getfield(beamsInitS, 'BeamSequence',['Item_', num2str(i)],'ControlPointSequence','Item_1','BeamLimitingDeviceAngle');
      beamGeometryInitS(1,i).couchAngle         = getfield(beamsInitS, 'BeamSequence',['Item_', num2str(i)],'ControlPointSequence','Item_1','PatientSupportAngle');
      beamGeometryInitS(1,i).gantryAngle        = getfield(beamsInitS, 'BeamSequence',['Item_', num2str(i)],'ControlPointSequence','Item_1','GantryAngle');
      try
        beamGeometryInitS(1,i).headInOut        = getfield(beamsInitS, 'PatientSetupSequence','Item_1','PatientPosition');
      end

     try
         beamGeometryInitS(1,i).apertureType    = getfield(beamsInitS, 'BeamSequence',['Item_', num2str(i)],'BeamLimitingDeviceSequence','Item_3','RTBeamLimitingDeviceType');
     catch
         beamGeometryInitS(1,i).apertureType    = '';
     end

     nwedges = getfield(beamsInitS,'BeamSequence',['Item_', num2str(i)],'NumberOfWedges');
     if  nwedges >0
        beamGeometryInitS(1,i).wedgeAngle         = getfield(beamsInitS, 'BeamSequence',['Item_', num2str(i)],'WedgeSequence','Item_1','WedgeAngle');
        beamGeometryInitS(1,i).wedgeRotationAngle = getfield(beamsInitS, 'BeamSequence',['Item_', num2str(i)],'WedgeSequence','Item_1','WedgeOrientation');
     else
        beamGeometryInitS(1,i).wedgeAngle         = 0;     
     end

     try
        beamGeometryInitS(1,i).RxDosePerTxGy    = getfield(beamsInitS, 'FractionGroupSequence','Item_1','ReferencedBeamSequence',['Item_', num2str(i)],'BeamDose');
     end
     
     try
        monitorUnits                            = getfield(beamsInitS, 'FractionGroupSequence','Item_1','ReferencedBeamSequence',['Item_', num2str(i)],'BeamMeterset');
        beamGeometryInitS(1,i).MonitorUnitsPerTx  =  round(monitorUnits);
     end
     
     try
        beamGeometryInitS(1,i).numberOfTx       = getfield(beamsInitS, 'FractionGroupSequence','Item_1','NumberOfFractionsPlanned');
     end
end
