%Script to run Dose-recomputation using QIB
%
%APA, 03/27/2009
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

global planC
indexS = planC{end};

% --------------------------------- Option to Downsample CT
ButtonName = questdlg('Do you wish to downsample CT by factor of 2?');
if strcmpi(ButtonName,'yes')
    planC = getplanCDownSample(planC, planC{indexS.CERROptions}, 2);
end

% --------------------------------- Target Struture used to Scale dose (D98)
ptvStructNum = 13;

% --------------------------------- Clinical Dose used to Scale dose
clinicDoseNum = 1;

% --------------------------------- Name IMRTP
imrtpName = 'Leaf Seq 2';

%% --------------------------------- Inputs for QIB 
MCsolver = 3;
scatterThreshold = 0.1;
structNumsV = [5 6 7]; %Structure indices where dose needs to be calculated.
sampleRateV = [4 2 2];   %NOTE: Skin can be sampled at rate of 8, whereas targets and critical 
%                          structures can be sampled at rate of 2. This helps speed-up calculation 
%                          while maintaining dose accuracy for important structures. Same length as structNumsV

%% --------------------------------- Inputs for DPM
% MCsolver = 1; %1:DPM, 2:VMC++
% scatterThreshold = 11.2; %DPM
% structNumsV = []; %leave structure number empty since DPM computes dose over entire body
% sampleRateV = []; %leave empty for DPM calculation

%Change nhist and batch
nhist = 1e5; %per cm^2, use 1000000 for testing; %1M is 2% uncertainty, 4M is 1%
batch = 101; %must be unique for each calculation
planC_File = ''; %Leave empty since it is global.
leak = 0.032;
spectrum_File = '6MV10x10MDA.spectrum';
OutputError = 0; %not working for 1
whichBeam = 1;  %redefined later
PBMaxWidth = 10; %
gradsense = 25;
% MCsolver = 1; %1:DPM, 2:VMC++
saveIM = 0;
sourceModel = 0; %1 to use source model
doseToWater = 0;
fillWater = 0;
useWedge = 0;
inputPB = 0;
inputIM = 1;
Softening = 1;
UseFlatFilter = 1;
MLC = 0; %1?
TongueGroove = 0;
interactiveMode = 1;
LS_flag = 0;
K = 1;
% scatterThreshold = 11.2; %DPM
% structNumsV = []; %leave structure number empty since DPM computes dose over entire body
% sampleRateV = []; %leave empty for DPM calculation

% % --------------------------------- Inputs for QIB 
% MCsolver = 3;
% scatterThreshold = 0.1;
% structNumsV = [2 1 5 6 11]; %Structure indices where dose needs to be calculated.
% sampleRateV = [8 2 2 2 2]; %NOTE: Skin can be sampled at rate of 8, whereas targets and critical 
% %                           structures can be sampled at rate of 2. This helps speed-up calculation 
% %                           while maintaining dose accuracy for important structures
% 
% structNumsV = [11 12 9 6];
% sampleRateV = [2 2 2 2]; %same length as structNumsV

%% --------------------------------- Call dose calculation engine
try
    numBeams = planC{indexS.beams}(1).FractionGroupSequence.Item_1.NumberofBeams;
catch
    numBeams = planC{indexS.beams}(1).FractionGroupSequence.Item_1.NumberOfBeams;
end
beamletWeightC = {};
for whichBeam = 1:numBeams    
    %IMwDPM = beam2MCdose(leak, spectrum_File, planC_File, nhist, OutputError, whichBeam, PBMaxWidth, gradsense, MCsolver, saveIM, sourceModel, doseToWater, fillWater, useWedge, inputPB, inputIM, Softening, UseFlatFilter, MLC, TongueGroove, batch, interactiveMode, LS_flag, K, scatterThreshold);
    [IMwQIB(whichBeam), beamletWeightC{whichBeam}] = beam2MCdose_with_QIB(leak, spectrum_File, planC_File, nhist, OutputError, whichBeam, PBMaxWidth, gradsense, MCsolver, saveIM, sourceModel, doseToWater, fillWater, useWedge, inputPB, inputIM, Softening, UseFlatFilter, MLC, TongueGroove, batch, interactiveMode, LS_flag, K, scatterThreshold, structNumsV, sampleRateV);
end

if MCsolver == 1 %DPM
    % --------------------------------- Read dose from disk and apply Meter-Set
    [dose3Dsum] = calcDoseByBeamMeterset(planC, nhist, batch);
    doseName = 'DPM reCalc';

elseif MCsolver == 3 %QIB
    
    planC{indexS.IM}(1).IMDosimetry.beams = [IMwQIB.beams];
    planC{indexS.IM}.IMDosimetry.goals = IMwQIB(1).goals;
    planC{indexS.IM}.IMDosimetry.params = IMwQIB(1).params;
    clear IMwQIB
    planC{indexS.IM}.IMDosimetry.isFresh = 1;
    planC{indexS.IM}.IMDosimetry.name = imrtpName;
    planC{indexS.IM}.IMDosimetry.solutions = [];
    planC{indexS.IM}.IMDosimetry.assocScanUID = planC{indexS.scan}(1).scanUID;
    planC{indexS.IM}.IMDosimetry.solutions = [beamletWeightC{:}];
    [dose3D] = getIMDose(planC{indexS.IM}(end).IMDosimetry, [beamletWeightC{:}], structNumsV);    
    doseName = 'QIB reCalc';    
end

%% --------------------------------- Scale to clinical dose
doseNum = length(planC{indexS.dose});

%Scale based on PTV D98
reCalc_metric   = Dx(planC, ptvStructNum, doseNum, 98);
Clinical_metric = Dx(planC, ptvStructNum, clinicDoseNum, 98);

%Scale based on PTV meanDose
reCalc_metric   = meanDose(planC, ptvStructNum, doseNum, 'Absolute');
Clinical_metric = meanDose(planC, ptvStructNum, clinicDoseNum, 'Absolute');

planC{indexS.dose}(doseNum).doseArray = planC{indexS.dose}(doseNum).doseArray*Clinical_metric/reCalc_metric;

%Show dose in CERR
showIMDose(dose3D,doseName)
