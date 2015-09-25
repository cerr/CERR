function reSliceScan(scanNum,dSag,dCor,dTrans,planC)
%function reSliceScan(scanNum,dSag,dCor,dTrans,planC)
%
%This function re-slices the scan scanNum according to resolution dSag,dCor,dTrans
%INPUT: scanNum: Scan Index (1 if only one scan is present)
%       dSag   : Slice spacing in Sagittal direction
%       dCor   : Slice spacing in Coronal direction
%       dTrans : Slice spacing in Transverse direction
%       planC  : Optional input
%
%EXAMPLE:
%       scanNum = 1;
%       dSag=0.25; dCor=0.25; dTrans=0.4;
%       reSliceScan(scanNum,dSag,dCor,dTrans)
%
%APA, 12/02/2009
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
scanS = planC{indexS.scan}(scanNum);
[xVals, yVals, zVals] = getScanXYZVals(scanS);
newZVals = zVals(1):dTrans:zVals(end);
newXVals = xVals(1):dCor:xVals(end);
newYVals = yVals(1):-abs(dSag):yVals(end);
newGridInterval2 = newXVals(2) - newXVals(1);
newGridInterval1 = abs(newYVals(1) - newYVals(2));
sliceThickness = newZVals(2) - newZVals(1);

%Find structures belonging to scanNum
assocScanV = getStructureAssociatedScan(1:length(planC{indexS.structures}));
structNumV = find(assocScanV==scanNum);

oldScanInfo = planC{indexS.scan}(scanNum).scanInfo(1);
CTDatatype = class(planC{indexS.scan}(scanNum).scanArray);

%Store transformation to be applied later
transM = planC{indexS.scan}(scanNum).transM;

%Find nearest slices of the old scan to the new slices
for i=1:length(newZVals)
    nearestSlicesV(i) = findnearest(zVals,newZVals(i));
end

%Store old contours
contourC = {planC{indexS.structures}.contour};

%Delete old contours
for strNum = 1:length(structNumV)
    planC{indexS.structures}(structNumV(strNum)).contour = [];
end

try

    for slcNum = 1:length(newZVals)
        %Interpolate in z direction
        [slc, sliceXVals, sliceYVals] = getCTOnSlice(scanNum, newZVals(slcNum), 3, planC);
        slc = finterp2(sliceXVals, sliceYVals, double(slc), newXVals, newYVals, 1,0);
        slc = reshape(slc, [length(newYVals) length(newXVals)]);
        %Interpolate in x,y direction
        switch CTDatatype
            case 'uint8'
                slc = uint8(slc);
            case 'uint16'
                slc = uint16(slc);
            case 'uint32'
                slc = uint32(slc);
            case 'single'
                slc = single(slc);
        end
        newScanArray(:,:,slcNum) = slc;
        newScanInfo(slcNum) = oldScanInfo;
        newScanInfo(slcNum).grid1Units = newGridInterval1;
        newScanInfo(slcNum).grid2Units = newGridInterval2;
        newScanInfo(slcNum).sizeOfDimension1 = length(newYVals);
        newScanInfo(slcNum).sizeOfDimension2 = length(newXVals);
        newScanInfo(slcNum).zValue = newZVals(slcNum);
        newScanInfo(slcNum).sliceThickness = sliceThickness;
        
        %Interpolate structures on to this slice (Nearest Neighbor Interpolation)
        for strNum = 1:length(structNumV)
            contourS = contourC{structNumV(strNum)}(nearestSlicesV(slcNum));
            for segNum = 1:length(contourS.segments)
                if ~isempty(contourS.segments(segNum).points)
                    newPointsM = contourS.segments(segNum).points;
                    newPointsM(:,3) = newPointsM(:,3).^0 * newZVals(slcNum);
                    planC{indexS.structures}(structNumV(strNum)).contour(slcNum).segments(segNum).points = newPointsM;
                else
                    planC{indexS.structures}(structNumV(strNum)).contour(slcNum).segments(segNum).points = [];
                end
            end
        end
        
    end

    planC{indexS.scan}(scanNum).scanInfo  = newScanInfo;
    planC{indexS.scan}(scanNum).scanArray = newScanArray;
    
    %Restore old transformation matrix    
    planC{indexS.scan}(scanNum).transM = transM;    

    %Re-Raster and reUniformize
    planC{indexS.scan}(scanNum).uniformScanInfo             = [];
    planC{indexS.scan}(scanNum).scanArraySuperior           = [];
    planC{indexS.scan}(scanNum).scanArrayInferior           = [];
    planC{indexS.structureArray}(scanNum).indicesArray      = [];
    planC{indexS.structureArray}(scanNum).bitsArray         = [];
    planC{indexS.structureArrayMore}(scanNum).indicesArray  = [];
    planC{indexS.structureArrayMore}(scanNum).bitsArray     = [];


    %Re-Generate raster segments
    for strNum = 1:length(structNumV)
        planC{indexS.structures}(structNumV(strNum)).rasterized = 0;
        planC{indexS.structures}(structNumV(strNum)).rasterSegments = [];
    end
    planC = getRasterSegs(planC);

    %uniformize
    planC = setUniformizedData(planC);

catch

    %Restore old transformation matrix    
    planC{indexS.scan}(scanNum).transM = transM;
    
    %Restore old contours
    for strNum = 1:length(structNumV)
        planC{indexS.structures}(structNumV(strNum)).contour = contourC{structNumV(strNum)};
    end
    
end

