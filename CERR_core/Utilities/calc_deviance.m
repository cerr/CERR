function deviance = calc_deviance(trueStructNum,testStructNum,margin,planC)
% function deviance = calc_deviance(trueStructNum,testStructNum,margin,planC)
%
% Calculates the deviance in cc of testStructNum from trueStructNum
% 
% Example call:
% trueStructNum = 1;
% testStructNum = 2;
% margin = 0.2; % 2mm
% deviance = calc_deviance(trueStructNum,testStructNum,margin,planC);
%
% APA, 9/18/2017

if ~exist('planC','var')
    global planC
end
indexS = planC{end};

numStructs = length(planC{indexS.structures});

% Expand the test structure by amount equal to the margin
planC = createExpandedStructure(trueStructNum, margin, planC);
expandedStructNum = numStructs + 1;

% Contract the test structure by amount equal to the margin
planC = createExpandedStructure(trueStructNum, -margin, planC);
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
