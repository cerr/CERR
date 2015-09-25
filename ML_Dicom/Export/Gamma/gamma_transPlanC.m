function planC = gamma_transPlanC(planC)
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

indexS = planC{end};

oldScanSet = length(planC{indexS.scan});

for scanSet = 1:oldScanSet

    % the Scan Set will always be 1 as the 1st scan is deleted.
    planC = gamma_transScan(planC, 1);

end

for i = 1:length(planC{indexS.structures})
    planC{indexS.structures}(i).rasterized = 0;
    planC{indexS.structures}.rasterSegments = [];
end

planC{indexS.structureArray} = [];

planC = setUniformizedData(planC);