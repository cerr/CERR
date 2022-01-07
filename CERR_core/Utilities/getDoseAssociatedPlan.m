function assocPlanNumV = getDoseAssociatedPlan(doseNumV, planC)
% "getDoseAssociatedPlan"
%   Returns a vector with the corresponding associated scan for each 
%   dose number passed in structsV.
%
%   If planC is not specified, the global planC is used.
%
% APA 12/22/2021
%
%Usage:
%   assocPlanNumV = getDoseAssociatedPlan(dosesV, planC)
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

if ~exist('planC','var')
    global planC
end

indexS = planC{end};

% % Filter out "beam" doses
% sumType = {}; 
% for i=1:length(planC{indexS.dose})
%     sumType{i} = planC{indexS.dose}(i).DICOMHeaders.DoseSummationType; 
% end
% indBeamV = strcmp(sumType,'BEAM');
% planC{indexS.dose}(indBeamV) = [];

% list of SOPInstanceUID
SOPInstanceUIDv = {planC{indexS.beams}.SOPInstanceUID};

% Get plan that matches dose
for iDose = 1:length(doseNumV)   
    doseNum = doseNumV(iDose);
    ReferencedSOPInstanceUID = planC{indexS.dose}(doseNum)...
        .DICOMHeaders.ReferencedRTPlanSequence.Item_1.ReferencedSOPInstanceUID;
    
    assocPlanNumV(iDose) = find(strcmpi(ReferencedSOPInstanceUID,SOPInstanceUIDv));

end
