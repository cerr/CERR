function beamGeometryInitS = populate_planC_beamGeometry_field(beamsInitS, beamGeometryInitS)
% dicomrt_d2c_beam(beamGeometryInitS,indexS,plan,tags)
% [beamsInitS,beamGeometryInitS,tags] = dicomrt_d2c_beam(beamGeometryInitS,indexS,study,tags)
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

type='BEAM GEOMETRY';

% beamsInitS = temp_study_header;

% Get parameters
try
    beams=fieldnames(beamsInitS.BeamSequence);
    nbeams=size(beams,1);
catch
    return
end

% Update nimages
tags.nimages = nbeams;

%----------------------------------------------------------------------------------------

%Convert beam geometry
%Fill beamGeometryInitS.
% temp = beamGeometryInitS;
% t2 = cell(1,nbeams);
% [t2{:}] = deal(temp);
% beamGeometryInitS = [t2{:}];

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
    if isfield(eval(sprintf('beamsInitS.BeamSequence.%s.ControlPointSequence.Item_1',beams{i})),'BeamLimitingDevicePositionSequence')
        string = sprintf('%d, %d', eval(sprintf('beamsInitS.BeamSequence.%s.ControlPointSequence.Item_1.BeamLimitingDevicePositionSequence.Item_1.LeafJawPositions',beams{i})));
        beamGeometryInitS(1,i).file{1,2}          = ['"Collimator Setting X" ' string];
    
        %get collimator setting Y
        string = sprintf('%d, %d', eval(sprintf('beamsInitS.BeamSequence.%s.ControlPointSequence.Item_1.BeamLimitingDevicePositionSequence.Item_2.LeafJawPositions',beams{i})));
        beamGeometryInitS(1,i).file{1,3}          = ['"Collimator Setting Y" ' string];
    end
    
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
    
    try
        nwedges = getfield(beamsInitS,'BeamSequence',['Item_', num2str(i)],'NumberOfWedges');
    catch
        nwedges = getfield(beamsInitS,'BeamSequence',['Item_', num2str(i)],'NumberofWedges');
    end
    
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
    
    beamGeometryInitS(1,i).assocBeamsUID = beamsInitS.BeamUID;
end