function output = structureStats(structNum, planC)
%"structureStats"
%   Returns output, a struct containing the xyz coordinates for the
%   Center of mass(COM) of the mask of the structure, and the min 
%   and max extent of the structure.
%
%   If a transformation matrix exists for a structure's associated scan,
%   the coordinates are transformed using the matrix.
%
%JRA 3/12/04
%
%Usage:
%   function output = structureStats(structNum, planC)
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

if ~exist('planC')
    global planC;
end

indexS = planC{end};

%Get scan associated with structure.
scanSet = getStructureAssociatedScan(structNum, planC);

%Get mask of structure.
uniformStr = getUniformStr(structNum, planC);

%Get r,c,s of voxels inside uniformStr.
[r,c,s] = find3d(uniformStr);
nVoxInStruct = length(r);
clear uniformStr;

%Get scan's original x,y,z coordinates, and it's transformation matrix.
if isempty(planC{indexS.scan}(scanSet).uniformScanInfo)
    planC = setUniformizedData(planC);
end
[xV, yV, zV] = getUniformScanXYZVals(planC{indexS.scan}(scanSet));
transM = getTransM(planC{indexS.scan}(scanSet), planC);
voxVol = abs(xV(2)-xV(1)) * abs(yV(2)-yV(1)) * abs(zV(2)-zV(1));

%Get the x,y,z coords of points in the structure, and transform.
structXV = xV(c); clear c xV;
structYV = yV(r); clear r yV;
structZV = zV(s); clear s zV;
[xT, yT, zT] = applyTransM(transM, structXV, structYV, structZV);
clear structXV structYV structZV

%Find the bounding box around the structure.
minX = min(xT);
minY = min(yT);
minZ = min(zT);
maxX = max(xT);
maxY = max(yT);
maxZ = max(zT);

yCOM = mean(yT);
xCOM = mean(xT);
zCOM = mean(zT);

output.min = min([[minX, minY, minZ];[maxX, maxY, maxZ]]);
output.max = max([[minX, minY, minZ];[maxX, maxY, maxZ]]);
output.COM = [xCOM, yCOM, zCOM];
output.vol = voxVol * nVoxInStruct;
output.name = planC{indexS.structures}(structNum).structureName;