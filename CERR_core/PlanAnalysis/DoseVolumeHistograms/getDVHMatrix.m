function [planC, doseBinsV, volsHistV] = getDVHMatrix(planC, structNum, doseNum, numBins)
%"getDVHMatrix"
%   Wrapper function to get DVH data.  Use this to get the doseV/volsV
%   vectors used to represent DVH data for a structNum and doseNum.  If the
%   data has already been calculated and stored in the plan, the stored
%   data is returned, else new data is calculated using getDVH.  
%
%   Matching the requested structNum and doseNum to existing DVHs is done
%   using the structure's name, and the dose index.  If a stored DVH has a
%   dose index that is no longer accurate, incorrect data may be returned.
%
%   planC is an output argument in order to save the calculated DVH data
%   for future use.
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
%
%Usage:
%   [planC, doseBinsV, volsHistV] = getDVHMatrix(planC, structNum, doseNum)

indexS = planC{end};
volsHistV = [];
doseBinsV = [];

%Find all DVHs for structure structNum on dose doseNum.
structName = planC{indexS.structures}(structNum).structureName;

if nargin ~= 4 % load stored DVHs if numBins is not specified
    for DVHNum=1:length(planC{indexS.DVH})
        if strcmp(upper(planC{indexS.DVH}(DVHNum).structureName), upper(structName)) & planC{indexS.DVH}(DVHNum).doseIndex == doseNum & ~isempty(planC{indexS.DVH}(DVHNum).DVHMatrix)
            [doseBinsV, volsHistV] = loadDVHMatrix(DVHNum, planC);
        end
    end
end

if isempty(volsHistV)
    %Get doses and volumes of points in structure.
    [dosesV, volsV] = getDVH(structNum, doseNum, planC);
    
    %Try and get a binWidth from stateS.  If it doesnt exist, get it from
    %the CERROptions file (allows this function to be called outside CERR)
    global stateS;
    if (nargin ~=4) & ~isempty(stateS) & isfield(stateS, 'optS') & isfield(stateS.optS, 'DVHBinWidth') & ~isempty(stateS.optS.DVHBinWidth)
        binWidth = stateS.optS.DVHBinWidth;
        %Histogram the volumes by dose.
        [doseBinsV, volsHistV] = doseHist(dosesV, volsV, binWidth);
    elseif nargin ~= 4
        optS = CERROptions;
        binWidth = optS.DVHBinWidth;
        %Histogram the volumes by dose.
        [doseBinsV, volsHistV] = doseHist(dosesV, volsV, binWidth);
    elseif nargin == 4
        binWidth = max(dosesV)./numBins;
        %Histogram the volumes by dose.
        [doseBinsV, volsHistV] = doseHist(dosesV, volsV, binWidth);
    end
    
    %Create a new DVH element.
    DVHIndex = length(planC{indexS.DVH}) + 1;
    planC{indexS.DVH}(DVHIndex).volumeType      = 'absolute';
    planC{indexS.DVH}(DVHIndex).doseType        = 'absolute';
    planC{indexS.DVH}(DVHIndex).structureName   = structName;
    planC{indexS.DVH}(DVHIndex).doseIndex       = doseNum;
    planC{indexS.DVH}(DVHIndex).fractionGroupID = planC{indexS.dose}(doseNum).fractionGroupID;

    %Store computational results if numBins is not specified
    if nargin ~=4
        planC = saveDVHMatrix(DVHIndex, doseBinsV, volsHistV, planC);
    end
    
end

return;