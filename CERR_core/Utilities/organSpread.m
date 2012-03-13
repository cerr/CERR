function spread = organSpread(planC,structNum,doseNum)
%function spread = organSpread(planC,structNum,doseNum)
%
%This function computes the spread of input structure. Spread is the
%maximum distance (cm) along x,y or z direction.
%
%APA, 04/21/2010
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

global stateS
stateS.optS = CERROptions;
stateS.MLVersion = getMLVersion;

indexS = planC{end};

scanNum = getStructureAssociatedScan(structNum,planC);

isUniformizedStr = isUniformStr(structNum,planC);

if ~isUniformizedStr
    warning('Uniformizing Structure')
    planC = updateStructureMatrices(planC,structNum);
end

mask3M = getUniformStr(structNum,planC);
surfPoints = getSurfacePoints(mask3M);

[xVals, yVals, zVals] = getUniformScanXYZVals(planC{indexS.scan}(scanNum));

yV = yVals(surfPoints(:,1));
xV = xVals(surfPoints(:,2));
zV = zVals(surfPoints(:,3));

dx = max(xV) - min(xV);
dy = max(yV) - min(yV);
dz = max(zV) - min(zV);

spread = max([dx dy dz]);

return;
