function planC = copyStrToScan(structNum,scanNum,planC)
%function planC = copyStrToScan(structNum,scanNum,planC)
%
%This function derives a new structure from structNum which is associated
%to scanNum. The naming convention for this new structure is 
%[structName assoc scanNum]. If structNum is already associated to scanNum,
%the unchanged planC is returned back. 
%
%APA, 8/18/06
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
    global planC
end

indexS = planC{end};

%return if structNum is already associated to scanNum
assocScanNum = getAssociatedScan(planC{indexS.structures}(structNum).assocScanUID, planC);
if assocScanNum == scanNum
    warning(['Structure Number ',num2str(structNum),' is already assocoated with scan ',num2str(scanNum)])
    return;
end

% Structure names of all the structures in existing plan
strNamC = {planC{indexS.structures}.structureName};
strNamC(structNum) = [];

% Structure name of the one to be copied.
strName = planC{indexS.structures}(structNum).structureName;

%obtain r,c,s coordinates of scanNum's (new) x,y,z vals
newScanS = planC{indexS.scan}(scanNum);
[xNewScanValsV, yNewScanValsV, zNewScanValsV] = getScanXYZVals(newScanS);
[rNewScanValsV, cNewScanValsV, sNewScanValsV] = xyztom(xNewScanValsV, yNewScanValsV, zNewScanValsV, scanNum, planC, 1);

%obtain r,c,s coordinates of structure based on its associated (old) scan
[rStructValsV, cStructValsV, sStructValsV] = getUniformStr(structNum, planC);
[oldMask] = getUniformStr(structNum, planC);

%obtain x,y,z coordinates of voxels included within structure considering
%transM for old and new scan
[xOldScanValsV, yOldScanValsV, zOldScanValsV] = getUniformScanXYZVals(planC{indexS.scan}(assocScanNum));
xStructValsV = xOldScanValsV(cStructValsV);
yStructValsV = yOldScanValsV(rStructValsV);
zStructValsV = zOldScanValsV(sStructValsV);
if ~isfield(planC{indexS.scan}(scanNum),'transM') || isempty(planC{indexS.scan}(scanNum).transM) 
    transMold = eye(4);
else    
    transMold = planC{indexS.scan}(scanNum).transM;
end
if ~isfield(planC{indexS.scan}(assocScanNum),'transM') || isempty(planC{indexS.scan}(assocScanNum).transM) 
    transMnew = eye(4);
else    
    transMnew = planC{indexS.scan}(assocScanNum).transM;
end
transM = inv(transMold)*transMnew;
[xStructValsV, yStructValsV, zStructValsV] = applyTransM(transM, xStructValsV, yStructValsV, zStructValsV);


%create x,y,z mesh grids for both old and new scans, in the coordinate system of the new scan
[XOld,YOld,ZOld] = meshgrid(xOldScanValsV, yOldScanValsV, zOldScanValsV);
[XOldT, YOldT, ZOldT] = applyTransM(transM, XOld(:), YOld(:), ZOld(:));
XOld(:) = XOldT;
YOld(:) = YOldT;
ZOld(:) = ZOldT;
[XNew,YNew,ZNew] = meshgrid(xNewScanValsV, yNewScanValsV, zNewScanValsV);

%create new mask by interpolating between the x,y,z positions of the old mask
oldMaskDoubles = zeros(size(oldMask));
oldMaskDoubles(oldMask) = 1;
newMask = interp3(XOld,YOld,ZOld,oldMaskDoubles,XNew,YNew,ZNew);

%generate uniformized mask for this new structure
newScanUnifSiz = getUniformScanSize(newScanS);
maskM = zeros(newScanUnifSiz,'uint8');
maskM(newMask>=0.5) = 1;

%generate contours on slices out of uniform mask and add to planC
if any(strncmp(strName,strNamC,inf))
    % strname = [planC{indexS.structures}(structNum).structureName,' asoc ',num2str(scanNum)];
    strName = [strName,' asoc ',num2str(scanNum)];
end
planC = maskToCERRStructure(maskM, 1, scanNum, strName, planC);
