function planC = validateGamma_Plan(planC)
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

planC = validatePlan(planC);

indexS = planC{end};

if length(planC{indexS.dose})> 0

    [planC{indexS.dose}.doseUnits] = deal('Gy');

    for i = 1:length(planC{indexS.dose})

        if isempty(planC{indexS.dose}(i).assocScanUID)
            try
                planC{indexS.dose}(i).assocScanUID = planC{indexS.scan}(i).scanUID;
            catch
                planC{indexS.dose}(i).assocScanUID = planC{indexS.scan}(i-1).scanUID;
            end
        end

    end

end

%% Use Transforamtion Matrice to transform Scan and Structure
planC = gamma_transPlanC(planC);
