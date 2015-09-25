function planC = translateStruct(structNum,xyzT,structName,planC)
% 
% function planC = translateStruct(structNum,xyzT,structName,planC)
%
% This function creates a new structure by translating structNum by amounts
% xT, yT and zT in x,y,z directions respectively. Note that xyzT = [xT yT zT].
% structName must be a string to name the new structure.
% 
% Example:
%   planC = translateStruct(12,[-1 0 0],'moveStruct12');
%
% APA, 9/12/06
%
% LM DK compatible with CERR 3.0 
%
% See also GETUNIFORMSTR MASKTOCERRSTRUCTURE
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

%obtain scanNum associated to the structNum for CERR3

%scanNum = getAssociatedScan(planC{indexS.structures}(structNum).assocScanUID);

%scanNum is always 1 for CERR2

scanNum =  getStructureAssociatedScan(structNum, planC);
 
%obtain r,c,s coordinates of scan x,y,z vals

scanS = planC{indexS.scan}(scanNum);

[xUnifScanValsV, yUnifScanValsV, zUnifScanValsV] = getUniformScanXYZVals(scanS);

[rScanValsV, cScanValsV, sScanValsV] = xyztom(xUnifScanValsV, yUnifScanValsV, zUnifScanValsV,scanNum, planC, 1);

 

%obtain r,c,s coordinates of structure based on its associated scan

rcsStructValsV = getUniformStr(structNum);

scanUnifSiz = getUniformScanSize(scanS);

rcsStructValsV = find(rcsStructValsV);

[rStructValsV, cStructValsV, sStructValsV] = ind2sub(scanUnifSiz,rcsStructValsV);

 

%obtain x,y,z coordinates of voxels included within the structure

xStructValsV = xUnifScanValsV(cStructValsV);

yStructValsV = yUnifScanValsV(rStructValsV);

zStructValsV = zUnifScanValsV(sStructValsV);

 

%translate the x,y,z pints included within the structure by specified amount

xStructValsV = xStructValsV + xyzT(1);

yStructValsV = yStructValsV + xyzT(2);

zStructValsV = zStructValsV + xyzT(3);

 

%convert the translated x,y,z vals of structure to r,c,s of scanNum

[rStructValsV, cStructValsV, sStructValsV] = xyztom(xStructValsV, yStructValsV, zStructValsV,scanNum, planC, 1);

rStructValsV = round(rStructValsV);

rStructValsV = clip(rStructValsV,min(rScanValsV),max(rScanValsV),'limits');

cStructValsV = round(cStructValsV);

cStructValsV = clip(cStructValsV,min(cScanValsV),max(cScanValsV),'limits');

sStructValsV = round(sStructValsV);

sStructValsV = clip(sStructValsV,min(sScanValsV),max(sScanValsV),'limits');

 

%generate uniformized mask for this new structure

maskM = zeros(scanUnifSiz);

indicesWithinSkinV = sub2ind(scanUnifSiz,rStructValsV,cStructValsV,sStructValsV);

maskM(indicesWithinSkinV) = 1;

 

%generate contours on slices out of uniform mask and add to planC

planC = maskToCERRStructure(maskM, 1, scanNum, structName, planC);
