function [TCP_all_plans,TCPe_all_plans,meanDoseV,stdDoseV,DVHm,volsV,shiftXm,shiftYm,shiftZm] = batch_simulate_organ_motion()
%function [DVH_out, DVHm, volsV] = batch_simulate_organ_motion(planC,structNum,doseNum)
%
%APA, 09/21/2012
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


scanLocation = 'C:\Projects\forPer\IGRT_Prostate_simulations\CERR_plans_consistently_named';

dirS = dir(scanLocation);
dirS(1:2) = [];

gamma50V = [4 4.5 5];
D50v = 73:86;

load('L:\Data\IGRT_Prostate_Per\DREES_DVH_data.mat')
isIGRTv = [ddbs.isIGRT];
ddbsFileC = {ddbs.fileName};

% get gammma50 and D50 for Refined and NCCC models.
[~,~,rawC] = xlsread('C:\Projects\forPer\IGRT_Prostate_simulations\For Cox analysis_2012-10-12.xlsx','D50 Gamma50 Parameters');
mrnC = rawC(2:end,1);
D50_refinedV = [rawC{2:end,2}];
gamma50_refinedV = [rawC{2:end,3}];
D50_NCCCv = [rawC{2:end,4}];
gamma50_NCCCv = [rawC{2:end,5}];

for planNum = 1:length(dirS)
    disp(planNum)
    fileName = fullfile(scanLocation,dirS(planNum).name);
    load(fileName)
    indexS = planC{end};

    [~,igrtInd] = ismember(strtok(dirS(planNum).name,'.'),ddbsFileC);
    
    igrtFlag = isIGRTv(igrtInd);
    
    mrn = strtok(fliplr(strtok(fliplr(fileName),'\')),'_');
    mrnInd = strmatch(mrn,mrnC,'exact');
    
    structurenamesC = {planC{indexS.structures}.structureName};

    ctvPostIndex = getMatchingIndex('ctv_1_posterior',lower(structurenamesC),'exact');   
    planningMarginPosteriorIndex = getMatchingIndex('planning_margin_posterior',lower(structurenamesC),'exact');  
    structNumsV = [ctvPostIndex planningMarginPosteriorIndex];
    structNumsV = [getMatchingIndex('ctv_1',lower(structurenamesC),'exact') structNumsV];
    doseIndex = 1;
    [meanDoseV{planNum}, stdDoseV{planNum}, DVHm{planNum}, volsV{planNum}, shiftXv, shiftYv, shiftZv] = simulate_organ_motion(planC,structNumsV,doseIndex, igrtFlag);    
    shiftXm(planNum,:) = shiftXv;
    shiftYm(planNum,:) = shiftYv;
    shiftZm(planNum,:) = shiftZv;
    
    % calculate TCP
    clear TCP TCPe
    for structCount = 1:length(DVHm{planNum})        
        for iTrial = 1:size(DVHm{planNum}{structCount},2)
            
            meanDoseCTV = mean(DVHm{planNum}{structCount}(:,iTrial));
            numVoxels = size(DVHm{planNum}{structCount},1);
            for gamma50 = gamma50V
                for D50 = D50v
                    fieldName = repSpaceHyp(['gamma50_',num2str(gamma50),'_D50_',num2str(D50)]);
                    TCP(structCount,iTrial).(fieldName) = 1/(1+exp(4*gamma50*(1-meanDoseCTV/D50)));
                    TCPx_elements = (1./(1+exp(4*gamma50*(1-DVHm{planNum}{structCount}(:,iTrial)/D50)))).^(1/numVoxels); % calculate this for each matix element
                    fieldName = repSpaceHyp(['gamma50_',num2str(gamma50),'_D50_',num2str(D50)]);
                    TCPe(structCount,iTrial).(fieldName) = prod(TCPx_elements(:)); % multiply all elements
                end
            end
            
            gamma50 = gamma50_refinedV(mrnInd);
            D50 = D50_refinedV(mrnInd);
            TCP(structCount,iTrial).Refined_model = 1/(1+exp(4*gamma50*(1-meanDoseCTV/D50)));
            TCPx_elements = (1./(1+exp(4*gamma50*(1-DVHm{planNum}{structCount}(:,iTrial)/D50)))).^(1/numVoxels);
            TCPe(structCount,iTrial).Refined_model = prod(TCPx_elements(:));
            
            gamma50 = gamma50_NCCCv(mrnInd);
            D50 = D50_NCCCv(mrnInd);
            TCP(structCount,iTrial).NCCC_model = 1/(1+exp(4*gamma50*(1-meanDoseCTV/D50)));
            TCPx_elements = (1./(1+exp(4*gamma50*(1-DVHm{planNum}{structCount}(:,iTrial)/D50)))).^(1/numVoxels);
            TCPe(structCount,iTrial).NCCC_model = prod(TCPx_elements(:));
            
        end
    end
    
    TCP_all_plans{planNum} = TCP;
    TCPe_all_plans{planNum} = TCPe;
    
end


