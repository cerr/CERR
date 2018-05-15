function [xDwCentr,yDwCentr,zDwCentr] = calc_doseWeightedCentroid(structNum,doseNum,normalizeFlag,planC)
%function [xDwCentr,yDwCentr,zDwCentr] = calc_doseWeightedCentroid(structNum,doseNum,normalizeFlag,planC)
%
% This function returns the dose-weighted centroid for the input structure and dose.
%
% INPUTS:
% structNum: structure index within the planC object
% doseNum: dose index within the planC object
% normalizeFlag: Flag to normalize the centroid between 0 and 1.
% If normalizeFlag == 1, the structure coordinates are scaled between and 0
% and 1 based on min/max coordinates along that dimension. x,y,z are based
% on RTOG coordinate system: https://github.com/cerr/CERR/wiki/Coordinate-system
% planC: can be accessed from Viewer by using 'global planC' or by loading
% the CERR .mat file in memory.
%
% OUTPUTS:
% x,y,z: dose weighted centroid coordinates
%
% Example:
% 
% structNum = 10;
% doseNum = 1;
% normFlg = 1;
% global planC
% [x,y,z] = calc_doseWeightedCentroid(structNum,doseNum,normFlg,planC)
% 
%APA, 05/15/2018
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

%Check if plan passed, if not use global.
if ~exist('planC')
    global planC;
end
indexS = planC{end};

[iV,jV,kV] = getUniformStr(structNum, planC);
assocScanNum = getStructureAssociatedScan(structNum,planC);
[xV,yV,zV] = getUniformScanXYZVals(planC{indexS.scan}(assocScanNum));
xCalcV = xV(jV);
yCalcV = yV(iV);
zCalcV = zV(kV);

%Get scan transM
transM_scan = getTransM('scan',assocScanNum,planC);
if isempty(transM_scan)
    transM_scan = eye(4);
end 

%Get dose transM
transM_dose = getTransM('dose',doseNum,planC);
if isempty(transM_dose)
    transM_dose = eye(4);
end

%Apply transM to dose calc pts
if ~isequal(transM_scan,transM_dose)
    [xCalcV, yCalcV, zCalcV] = applyTransM(transM_scan*inv(transM_dose), xCalcV, yCalcV, zCalcV);
    [jnk,jnk,zV] = applyTransM(transM_scan*inv(transM_dose), zV*0, zV*0 ,zV);
end

dosesV = getDoseAt(doseNum, xCalcV, yCalcV, zCalcV, planC);

%Normalize x,y,z coordinates
if normalizeFlag
    xCalcV = (xCalcV - min(xCalcV)) ./ (max(xCalcV) - min(xCalcV));
    yCalcV = (yCalcV - min(yCalcV)) ./ (max(yCalcV) - min(yCalcV));
    zCalcV = (zCalcV - min(zCalcV)) ./ (max(zCalcV) - min(zCalcV));
end

xDwCentr = sum(dosesV.*xCalcV)/sum(dosesV);
yDwCentr = sum(dosesV.*yCalcV)/sum(dosesV);
zDwCentr = sum(dosesV.*zCalcV)/sum(dosesV);

