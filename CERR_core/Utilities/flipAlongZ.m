function planC = flipAlongZ(scanNum)
% function planC = flipAlongZ(scanNum)
%
% Flip scan, structures and doses along Z direction
%
% USAGE:
% global planC
% scanNum = 1;
% planC = flipAlongZ(scanNum)
%
% APA, 05/17/2010
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

[xVals, yVals, zVals] = getScanXYZVals(planC{indexS.scan}(scanNum));

zMin = min(zVals);
zMax = max(zVals);

[assocScansV, relStructNumV] = getStructureAssociatedScan(1:length(planC{indexS.structures}),planC);

strV = find(assocScansV == scanNum);

%% Flip structures
for strNum = 1:length(strV)
    contourS = planC{indexS.structures}(strV(strNum)).contour;
    [numRows, numCols] = size(contourS);
    if numRows == 1
        contourS = fliplr(contourS); 
    else
        contourS = flipud(contourS); 
    end    
    numSlices = length(contourS);
    for slcNum = 1:numSlices
        zVal = zMin + zMax - zVals(numSlices-slcNum+1);
        for segNum = 1:length(contourS(slcNum).segments)
            pointsM = contourS(slcNum).segments(segNum).points;
            if ~isempty(pointsM)                               
                pointsM(:,3) = pointsM(:,3).^0*zVal;
                contourS(slcNum).segments(segNum).points = pointsM;
            end
        end
    end
    planC{indexS.structures}(strV(strNum)).contour = contourS;
end

%% Flip Scan
planC{indexS.scan}(scanNum).scanArray = flipdim(planC{indexS.scan}(scanNum).scanArray,3);
[numRows, numCols] = size(planC{indexS.scan}(scanNum).scanInfo);
if numRows == 1
    planC{indexS.scan}(scanNum).scanInfo = fliplr(planC{indexS.scan}(scanNum).scanInfo);
else
    planC{indexS.scan}(scanNum).scanInfo = flipud(planC{indexS.scan}(scanNum).scanInfo);
end
numSlices = length(planC{indexS.scan}(scanNum).scanInfo);
for slcNum = 1:numSlices
    planC{indexS.scan}(scanNum).scanInfo(slcNum).zValue = zMin + zMax - zVals(numSlices-slcNum+1);
end

%% Flip Dose
for doseNum = 1:length(planC{indexS.dose})
    assocScanNum = getAssociatedScan(planC{indexS.dose}(doseNum).assocScanUID,planC);
    if scanNum == assocScanNum
        doseZValues = planC{indexS.dose}(doseNum).zValues;
        doseZValues = zMin + zMax - doseZValues;
        [numRows, numCols] = size(doseZValues);
        if numRows == 1
            planC{indexS.dose}(doseNum).zValues = fliplr(doseZValues);
        else
            planC{indexS.dose}(doseNum).zValues = flipud(doseZValues);
        end
        planC{indexS.dose}(doseNum).doseArray = flipdim(planC{indexS.dose}(doseNum).doseArray,3);
    end    
end

%ReRaster and ReUniformize
reRasterAndUniformize

CERRRefresh
