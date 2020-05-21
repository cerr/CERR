function deviance = calc_deviance(trueStructNum,testStructNum,devMargin,planC)
% function deviance = calc_deviance(trueStructNum,testStructNum,devMargin,planC)
%
% Calculates the deviance of testStructNum from trueStructNum.
%
% Deviance = (volume of the true structure missed by the
% test structure + excess volume of the test structure over the true
% structure) / volume of the true structure.
%
% The true structure is 3-d contracted by the devMargin while computing the 
% volume of the true structure missed by the test structure. 
% 
% The true structure is 3-d expanded by the devMargin while computing the 
% excess volume of the test structure over the true structure. 
%
% Example call:
% trueStructNum = 1; % structure index in planC
% testStructNum = 2; % structure index in planC
% devMargin = 0.2; % cm
% deviance = calc_deviance(trueStructNum,testStructNum,devMargin,planC);
%
% APA, 9/18/2017

if ~exist('planC','var')
    global planC
end
indexS = planC{end};

numStructs = length(planC{indexS.structures});

% Expand the test structure by amount equal to the devMargin
planC = createExpandedStructure(trueStructNum, devMargin, planC);
expandedStructNum = numStructs + 1;

% Contract the test structure by amount equal to the devMargin
planC = createExpandedStructure(trueStructNum, -devMargin, planC);
contracttructNum = numStructs + 2;

% Create a structure that's equal to the excess test volume
planC = createDifferenceStructure(testStructNum,expandedStructNum, planC);
excessTestStructNum = numStructs + 3;

% Create a structure that's equal to the excess true volume
planC = createDifferenceStructure(contracttructNum,testStructNum, planC);
excessTrueStructNum = numStructs + 4;

% Calculate the excess test and true volumes in cc
excessTestVol = getStructureVol(excessTestStructNum,planC);
excessTrueVol = getStructureVol(excessTrueStructNum,planC);

% delete the intermediate structures
for strToDelete = numStructs+4:-1:numStructs+1
    planC = deleteStructure(planC,strToDelete);
end

% Add them up
deviance = excessTestVol + excessTrueVol;

% Normalize by the true volume
trueVol = getStructureVol(trueStructNum,planC);

deviance = deviance / trueVol;
