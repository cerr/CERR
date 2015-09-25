function planC = chopStructure(structureNum,minZ,maxZ,planC)
%function planC = chopStructure(structureNum,minZ,maxZ,planC)
%
%This function creates a new function which lies within minZ and maxZ.
%Use-case: To chop Skin structure so that dose is computed only around the prostate
%region.
%
%Usage: planC = chopStructure(2,-0.2,12.7)
%
%APA, 04/28/2009
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

if ~exist('planC','var')
    global planC
end
indexS = planC{end};

%Get associated scan number
scanNum = getStructureAssociatedScan(structureNum);

[xVals, yVals, zVals] = getScanXYZVals(planC{indexS.scan}(scanNum));

minSlice = max(find(zVals <= minZ));
maxSlice = min(find(zVals >= maxZ));

newStr = newCERRStructure(scanNum,planC);

numStructs = length(planC{indexS.structures});
toAdd = numStructs + 1;
for i=1:length(zVals)
    newStr.contour(i).segments.points = [];
end
newStr.contour(minSlice:maxSlice) = planC{indexS.structures}(structureNum).contour(minSlice:maxSlice);
newStr.structureName = [planC{indexS.structures}(structureNum).structureName, '_chopped'];
newStr.strUID = createUID('structure');
newStr.assocScanUID = planC{indexS.scan}(scanNum).scanUID;
newStr.visible = 1;
planC{indexS.structures} = dissimilarInsert(planC{indexS.structures}, newStr, toAdd);
planC = getRasterSegs(planC, toAdd);

planC = updateStructureMatrices(planC, toAdd);

stateS.structsChanged = 1;
sliceCallBack('refresh');
