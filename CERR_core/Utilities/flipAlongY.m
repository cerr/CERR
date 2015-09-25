function planC = flipAlongY(scanNum,planC)
% function planC = flipAlongY(scanNum,planC)
%
% Flip scan, structures and doses along Y direction
%
% USAGE:
% global planC
% scanNum = 1;
% planC = flipAlongY(scanNum)
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

yMin = min(yVals);
yMax = max(yVals);

[assocScansV, relStructNumV] = getStructureAssociatedScan(1:length(planC{indexS.structures}),planC);

strV = find(assocScansV == scanNum);

%Flip structures
for strNum = 1:length(strV)
    for slcNum = 1:length(planC{indexS.structures}(strV(strNum)).contour)
        for segNum = 1:length(planC{indexS.structures}(strV(strNum)).contour(slcNum).segments)
            pointsM = planC{indexS.structures}(strV(strNum)).contour(slcNum).segments(segNum).points;
            if ~isempty(pointsM)
                pointsM(:,2) = yMin + yMax - pointsM(:,2);
                planC{indexS.structures}(strV(strNum)).contour(slcNum).segments(segNum).points = pointsM;
            end
        end
    end
end

%Flip Scan
planC{indexS.scan}(scanNum).scanArray = flipdim(planC{indexS.scan}(scanNum).scanArray,1);

%Flip Dose
for doseNum = 1:length(planC{indexS.dose})
    assocScanNum = getAssociatedScan(planC{indexS.dose}(doseNum).assocScanUID,planC);
    if scanNum == assocScanNum
        planC{indexS.dose}(doseNum).doseArray = flipdim(planC{indexS.dose}(doseNum).doseArray,1);
    end    
end

%ReRaster and ReUniformize
reRasterAndUniformize

CERRRefresh
