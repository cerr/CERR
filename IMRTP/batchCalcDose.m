function planC = batchCalcDose(imIndex,gantryAngle,isoCenter)
% function batchCalcDose(imIndex,gantryAngle,isoCenter)
%
% This function adds a beam to the passed IM with specified gantryAngle and
% isoCenter. To create a new IM, use "createNewIM.m"
% gantryAngle: Angle in degrees
% isoCenter: is a structure with 'x','y','z' fields. isoCenter.x, isoCenter.y, isoCenter.z
% The dose is computed for all the structures specified by IM.goals
% array.
%
% APA, 03/20/2012

global planC
indexS = planC{end};

% Create a new beam
fieldNames = {{'beamNum'}, {'beamModality'}, {'beamEnergy'}, {'isocenter', 'x'}, {'isocenter', 'y'}, {'isocenter', 'z'}, ...
    {'isodistance'}, {'arcAngle'}, {'couchAngle'}, {'collimatorAngle'}, {'gantryAngle'}, {'beamDescription'}, ...
    {'beamletDelta_x'}, {'beamletDelta_y'}, {'dateOfCreation'}, {'beamType'}, ...
    {'zRel'}, {'xRel'}, {'yRel'}, {'sigma_100'}};

isAuto = ones(1,length(fieldNames));

IM = planC{indexS.IM}(imIndex).IMDosimetry;

% Create beam
numBeams = length(IM.beams);
newBeamIndex = numBeams + 1;
beam = createDefaultBeam(newBeamIndex, [], isAuto, fieldNames);
beam.gantryAngle = gantryAngle;
beam.isocenter = isoCenter;

% Get relative source positions
beam.zRel = 0;
beam.xRel =  beam.isodistance * sindeg(beam.gantryAngle);
beam.yRel =  beam.isodistance * cosdeg(beam.gantryAngle);

%RTOG positions of sources
beam.x = beam.xRel + isoCenter.x;
beam.y = beam.yRel + isoCenter.y;
beam.z = beam.zRel + isoCenter.z;

% Create an empty beamlets field
beam.beamlets = [];

% Add beam to IM and planC
if newBeamIndex == 1
    IM.beams = beam;
else
    IM.beams = dissimilarInsert(IM.beams, beam, newBeamIndex);
end

%Get surfacePoints of all target structures.
edgeS = getTargetSurfacePoints(IM);

%Get ROI StructureList
[structROIV, sampleRateV] = getROIStructureList(IM);

%Set PB vectors, determine which PBs are required to cover the target.
IM = getPBList(IM, edgeS);

updateM = zeros([length(IM.goals) length(IM.beams)]);

for beamNum = 1:length(IM.beams)
    if isempty(IM.beams(beamNum).beamlets)
        %re/compute beamlets for all structures
        updateM(:,beamNum) = 1;
    end
end 

%Here is where QIB and MC diverge. Update only passed struct/beam pairs
switch upper(IM.params.algorithm)
    case 'QIB'
        IM = updateQIBInfluence(IM, structROIV, sampleRateV, updateM);
    case 'VMC++'
        IM = updateVMCInfluence(IM, structROIV, sampleRateV, updateM);
end

% Add IM to planC
planC = addIM(IM, planC, imIndex);



function beam = createDefaultBeam(beamNum, beam, isAuto, fieldNames)
%Creates a beam with preset default values.
global planC;
indexS = planC{end};

fieldDefaults = {beamNum, 'photons', 6, 0, 0, 0, 100, 0, 0, 0, ...
    0, 'IM beam', 1, 1, 'date', 'IM', 0, 0, 0, 0.4};
beam = [];
for i=1:length(fieldNames)
    fN = fieldNames{i};
    beam = setfield(beam, fN{:}, fieldDefaults{i});
end
beam = conditionBeam(beamNum, beam, isAuto, fieldNames);

function beam = conditionBeam(beamNum, beam, isAuto, fieldNames)
%Sets values that should not be changed in a beam.
global planC;
indexS = planC{end};
autoFields = {beamNum, 'photons', 6, 'COM', 'COM', 'COM', 100, 0, 0, 0, ...
    0, 'IM beam', 1, 1, date, 'IM', 0, beam.isodistance * sindeg(beam.gantryAngle),...
    beam.isodistance * cosdeg(beam.gantryAngle), 0.4};

for i=1:length(fieldNames)
    if isAuto(i)
        fN = fieldNames{i};
        beam = setfield(beam, fN{:}, autoFields{i});
    end
end
