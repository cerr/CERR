function COMSI = comsi_lung_normalized(planC,structNum,doseNum)
%function COMSI = comsi_lung_normalized(planC,structNum,doseNum)
%
%This function returns the COMSI for input structure and dose. The COMSI is
%normalized w.r.t. LUNG.
%
% This function can be used with the batch extractor.
%
%APA, 04/16/2007
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
xCalc = xV(jV);
yCalc = yV(iV);
zCalc = zV(kV);

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
    [xCalc, yCalc, zCalc] = applyTransM(transM_scan*inv(transM_dose), xCalc, yCalc, zCalc);
    [jnk,jnk,zV] = applyTransM(transM_scan*inv(transM_dose), zV*0, zV*0 ,zV);
end
%

dosesV = getDoseAt(doseNum, xCalc, yCalc, zCalc, planC);
COM_z = sum(dosesV.*zCalc)/sum(dosesV);
%COMSI = (COM_z-min(zCalc))/(max(zCalc)-min(zCalc));


% Find totallung structure to normalize
strC = {planC{indexS.structures}.structureName};
lungStr = 'totallung';
lungIndex = getMatchingIndex(lungStr,strC,'exact');
if isempty(lungIndex)
    lungIndex = getMatchingIndex('lung',strC,'regex');
    if ~isempty(lungIndex)
        lungIndex = lungIndex(1);
    else
        COMSI = NaN;
        warning('Could not find lung structure')
        return;
    end
        
end

%Normalize with respect to lungIndex
[iV,jV,kV] = getUniformStr(lungIndex, planC);
zLungV = zV(kV);
COMSI = 1 - (COM_z-min(zLungV))/(max(zLungV)-min(zLungV));
