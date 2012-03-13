%script to run the Monte Carlo code
%call for multiple beams
%Vanessa Clark, 2/1/08, modified AA 2/18/08
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

postProcessing = 0; %outdated? %prepare for input to priPresOpt and save planC
CERR3planC_File = '/mnt/usb1/vanessa/cases/MCtest/case1.mat';%'C:\research\largeDataFiles\prioritizedOptimization\cases\case50_wIM_7b_wMoat_wOuterHotspot_CERR3.mat';
saveName = '/mnt/usb1/vanessa/cases/MCtest/case1.mat';%'C:\research\largeDataFiles\prioritizedOptimization\cases\casesRenumbered\case50_wMCIM.mat';

beamNums = 1:7;%7%1:7%[2 3 5 6]%1:7

% cd /home/matlab/vanessa/work/planCheckBeta/CERR/planCheck/MC/ %/home/matlab/vanessa/work/planCheck/MC/ %c:\cvsroot\plancheckbeta\cerr\plancheck\mc\
% genpath('/home/matlab/vanessa/work/planCheckBeta/'); %'c:\cvsroot\plancheckbeta\')

leak = 0.032;
spectrum_File = '6MV10x10MDA.spectrum';
planC_File = '/mnt/usb1/vanessa/cases/MCtest/case1.mat';%'C:\research\largeDataFiles\prioritizedOptimization\cases\case50_wIM_7b_wMoat_wOuterHotspot.mat';%'C:\research\largeDataFiles\prioritizedOptimization\cases\casesRenumbered\case1.mat';%'\\BIOR-02\Biorsan$\bioruser\clark\ExampleForJingAndAditya\case1_1_0.015_qsStep2_1_res.mat';
planC_File = 'C:\Projects\CERR support\forVanessa\case1_1_0.015_qsStep2_1_res.mat';

nhist = 500; %for testing 1000000; %1M is 2% uncertainty, 4M is 1% %name
OutputError = 0; %not working for 1
%whichBeam = 4; %for IMRT, which beam we're calculating, %output file name
PBMaxWidth = 10; %
gradsense = 25;
MCsolver = 1;
saveIM = 1;
sourceModel = 1;
doseToWater = 0;
fillWater = 0;
useWedge = 0;
inputPB = 0;
inputIM = 1;
Softening = 1;
UseFlatFilter = 1;
MLC = 0; %1?
TongueGroove = 0;
batch = 1; %name
interactiveMode = 1;
LS_flag = 0;

%IM:
%c:\research\largeDataFiles\prioritizedOptimization\cases\casesRenumbered\case50_IM.mat

%% ---------------------------- Use DPB to compute beamlets
%  ---------------------------- Note: For the first pass solution/s is all ones or empty
for whichBeam = beamNums
    IMwDPM = DPMpcOneBeam_aavc(leak, spectrum_File, planC_File, nhist, OutputError, whichBeam, PBMaxWidth, gradsense, MCsolver, saveIM, sourceModel, doseToWater, fillWater, useWedge, inputPB, inputIM, Softening, UseFlatFilter, MLC, TongueGroove, batch, interactiveMode, LS_flag);    
    %Combine IM's from disk or ??. Also, should it be end+1 ??
    %planC{indexS.IM}(end).IMDosimetry = IMwDPM;
end


%% ------------------------------------------  Load planC
global planC
load(planC_File)
indexS = planC{end};

%% ----------------------------- Call the Prioratized Optimization code
%  ----------------------------- Note: This function uses global planC and populates the solutions field for last IM
%priPresOpt_single

%% ------------------------------ Call Leaf Sequencer
beamWeights = planC{indexS.IM}(end).IMDosimetry.solution(end).beamletWeights;
[M, pos, xPts, yPts] = getMatricesToSegmentFromCERR(beamWeights);
%Generate Leaf Sequencer LS structure array (each index corresponds to beam)
[LeafSeq,MU] = getLeafSeqStruct(M,pos);
planC{indexS.IM}(end).IMDosimetry.LeafSeq.LS = LeafSeq;
planC{indexS.IM}(end).IMDosimetry.LeafSeq.MU = MU;
%Save planC

%% ------------------------------- Use DPB to compute beamlets using Leaf Sequences
for whichBeam = beamNums
    IMwDPM = DPMpcOneBeam_aavc(leak, spectrum_File, planC_File, nhist, OutputError, whichBeam, PBMaxWidth, gradsense, MCsolver, saveIM, sourceModel, doseToWater, fillWater, useWedge, inputPB, inputIM, Softening, UseFlatFilter, MLC, TongueGroove, batch, interactiveMode, LS_flag);    
    %Combine IM's from disk or ??. Also, should it be end+1 ??
    %planC{indexS.IM}(end).IMDosimetry = IMwDPM;
end

%dose3D = getIMDose(planC{indexS.IM}(end).IMDosimetry, weightMU, 8);
%showIMDose(dose3D,'testLS',1)

%% --------------------------------- Read dose from disk and apply weights
%Assume current directory is the one where dose files are written
dirS = dir(cd);
fileNameC = {dirS.name};
MU = planC{indexS.IM}(end).IMDosimetry.LeafSeq.MU;
dose3M = [];
for beamNum = 1:length(planC{indexS.IM}(end).IMDosimetry.beams)
    doseFileName = ['dose3D_',num2str(beamNum),'_',num2str(nhist),'_',num2str(batch)];
    load(doseFileName)
    if isempty(dose3M)
        dose3M = sum(MU{beamNum})*dose3D;
    else
        dose3M = dose3M + sum(MU{beamNum})*dose3D;
    end
end
showIMDose(dose3M,'testLS',1)

%% ------------------------------- Save planC

%%
return;
