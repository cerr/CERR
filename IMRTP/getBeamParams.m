function beamParamsS = getBeamParams(planC)

if ~exist('planC','var')
    global planC;
end

indexS = planC{end};

% Get number of beams
try
    numBeams = planC{indexS.beams}(1).FractionGroupSequence.Item_1.NumberofBeams;
catch
    numBeams = planC{indexS.beams}(1).FractionGroupSequence.Item_1.NumberOfBeams;
end

%Gantry angle, couch angle, collimator angle, isocenter, isodistance and beamEnergy :
for beamNum = 1:numBeams
    refBeamStr = ['Item_',num2str(beamNum)];
    bsBeamNumbersV(beamNum) = planC{indexS.beams}(1).BeamSequence.(refBeamStr).BeamNumber;
    fractionBeamNumber(beamNum) = planC{indexS.beams}(1).FractionGroupSequence.Item_1.ReferencedBeamSequence.(refBeamStr).ReferencedBeamNumber;
end
for beamNum = 1:numBeams
    refBeamNumber = find(bsBeamNumbersV == fractionBeamNumber(beamNum));
    beamStr = ['Item_',num2str(refBeamNumber)];    
    bs = planC{indexS.beams}(1).BeamSequence.(beamStr);
    if ~isfield(planC{indexS.beams}(1).PatientSetupSequence,(beamStr))
        position = {planC{indexS.beams}(1).PatientSetupSequence.(beamStr).PatientPosition};
    else
        position = {planC{indexS.beams}(1).PatientSetupSequence.(beamStr).PatientPosition};
    end
    gantryAngleV(beamNum) = bs.ControlPointSequence.Item_1.GantryAngle;
    couchAngleV(beamNum) = bs.ControlPointSequence.Item_1.PatientSupportAngle;
    collimatorAngleV(beamNum) = bs.ControlPointSequence.Item_1.BeamLimitingDeviceAngle;
    isocenterV(beamNum) = calc_beam_isocenter(bs, position);
    isoDistanceV(beamNum) = bs.SourceAxisDistance/10;
    beamEnergy = bs.ControlPointSequence.Item_1.NominalBeamEnergy;
    if abs(beamEnergy-6) < abs(beamEnergy-18)
        beamEnergyV(beamNum) = 6;
    else
        beamEnergyV(beamNum) = 18;
    end    
end

beamParamsS.gantryAngleV = gantryAngleV;
beamParamsS.couchAngleV = couchAngleV;
beamParamsS.collimatorAngleV = collimatorAngleV;
beamParamsS.isocenterV = isocenterV;
beamParamsS.isoDistanceV = isoDistanceV;
beamParamsS.beamEnergyV = beamEnergyV;

end

function isocenter = calc_beam_isocenter(bs,position)

% Isocenter:
iC = bs.ControlPointSequence.Item_1.IsocenterPosition;

if strcmpi(position, 'HFP')
    isocenter.x = iC(1)/10;
    isocenter.y = iC(2)/10;
    isocenter.z = -iC(3)/10;
else
    isocenter.x = iC(1)/10;
    isocenter.y = -iC(2)/10;
    isocenter.z = -iC(3)/10;
end
end

