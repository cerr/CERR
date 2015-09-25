function struct2dose(strucNumsV)
%function struct2dose(strucNumsV)
%
%This function converts structure/s in strucNumsV to a dose distribution.
%If strucNumsV is an array of srtucture numbers, then the dose distribution
%represents an agreement between these structures. i.e. higher the dose,
%greater the agreement and vice versa.
%
%APA, 02/06/2010
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


global planC stateS
indexS = planC{end};

scanNumsV = getStructureAssociatedScan(strucNumsV, planC);
if length(unique(scanNumsV)) > 1
    error('All structures passed in strucNumsV must be associated to same scan');    
end

scanNum = scanNumsV(1);

%Get dose mask
mask3M = getUniformStr(strucNumsV(1));
for i = 2:length(strucNumsV)
    strNum = strucNumsV(i);
    mask3M = mask3M + getUniformStr(strNum);
end

%Get Dose size
[xV, yV, zV] = getUniformScanXYZVals(planC{indexS.scan}(scanNum));
W = size(mask3M);
setIndex = length(planC{indexS.dose}) + 1;

% Initialize dose
doseInitS = initializeCERR('dose');

doseInitS(1).doseArray = mask3M;
doseInitS(1).imageType='DOSE';
doseInitS(1).caseNumber=1;
doseInitS(1).doseNumber= setIndex;
doseInitS(1).doseType='PHYSICAL';
doseInitS(1).doseUnits='GRAYS';
doseInitS(1).doseScale=1;
doseInitS(1).fractionGroupID= 'Structure Mask';
doseInitS(1).orientationOfDose='TRANSVERSE';
doseInitS(1).numberOfDimensions=length(W);
doseInitS(1).sizeOfDimension1=W(2);
doseInitS(1).sizeOfDimension2=W(1);
doseInitS(1).sizeOfDimension3=W(3);
doseInitS(1).assocScanUID = planC{indexS.scan}(scanNum).scanUID;
doseInitS(1).doseUID = createUID('DOSE');
grid2Units = xV(2)-xV(1);
grid1Units = yV(1)-yV(2);
doseInitS(1).horizontalGridInterval = grid2Units;
doseInitS(1).verticalGridInterval= - abs(grid1Units);
doseInitS(1).coord1OFFirstPoint =  xV(1);
doseInitS(1).coord2OFFirstPoint =  yV(1);
doseInitS(1).zValues = zV;
planC{indexS.dose} = dissimilarInsert(planC{indexS.dose},doseInitS, setIndex,[]);
stateS.doseToggle = 1;
stateS.doseSetChanged = 1;
stateS.doseSet = setIndex;
CERRRefresh

return;
