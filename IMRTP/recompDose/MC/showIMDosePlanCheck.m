%Function to place dose into the running CERR plan.
%Just edit the strings below.
%JOD.

% [CTUniform3D, CTUniformInfoS] = getUniformizedCTScan;

register = 'UniformCT';  %Currently only option supported.  Dose has the same shape as the uniformized CT scan.
doseError = [];
fractionGroupID = 'CERR test';
doseEdition = 'CERR test';
description = 'Test PB distribution.'
overWrite = 'no';  %Overwrite the last CERR dose?
dose2CERR(dose3D,doseError,fractionGroupID,doseEdition,description,register,[],overWrite);

global planC;
global stateS;
indexS = planC{end};

stateS.doseToggle = 1;

stateS.doseSetChanged = 1;
stateS.CTDisplayChanged = 1;
stateS.structsChanged = 1;

stateS.doseSet = length(planC{indexS.dose});
%plancheckCallback('refresh');