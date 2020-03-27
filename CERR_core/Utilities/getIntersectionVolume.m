function [intersectVol, planC] = getIntersectionVolume(structNum1,structNum2,planC)
%function intersectVol = getIntersectionVolume(structNum1,structNum2,planC)
%
%This function computes intersection volume between structNum1 and structNum2
%
%APA, 03/09/2009
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

scanNum1 = getStructureAssociatedScan(structNum1,planC);
scanNum2 = getStructureAssociatedScan(structNum2,planC);

if scanNum1 ~= scanNum2
    error('Both structures must be associated with same scan.')    
end

scanNum = scanNum1;

[rasterSegs1, planC] = getRasterSegments(structNum1,planC);
[rasterSegs2, planC] = getRasterSegments(structNum2,planC);

% Return 0 if any of the rastersegments are empty
if isempty(rasterSegs1) || isempty(rasterSegs2)
    intersectVol = 0;
    return
end

%Generate 3D rasterSegments of intersection volume
rasterSegs = structIntersect(rasterSegs1, rasterSegs2, scanNum, planC);

%Generate 3D mask of intersection volume
mask3M = rasterToMask(rasterSegs, scanNum, planC);

[xU,yU,zU] = getUniformScanXYZVals(planC{indexS.scan}(scanNum));

dx = abs(xU(2)-xU(1));
dy = abs(yU(2)-yU(1));
dz = abs(zU(2)-zU(1));

vol = dx*dy*dz;

intersectVol = vol*length(find(mask3M));
