function rS = getSliceRasterSegs(structNum, sliceNum)
%"calcSliceRasterSegs"
%   Returns the rasterSegments for one structure on a single slice.
%   Used to avoid recalculation of rasterSegment data that has not changed
%   when making small contour modifications.
%
%JRA 07/06/04
%
%Usage:
%   function rS = getSliceRasterSegs(structNum, slice, planC)
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

global planC
global stateS
indexS = planC{end};

segOptS.ROIxVoxelWidth = planC{indexS.scan}.scanInfo(1).grid1Units;
segOptS.ROIyVoxelWidth = planC{indexS.scan}.scanInfo(1).grid2Units;
segOptS.ROIImageSize   = [planC{indexS.scan}.scanInfo(1).sizeOfDimension1  planC{indexS.scan}.scanInfo(1).sizeOfDimension2];

%Get any offset of CT scans to apply (neg) to structures
if ~isempty(planC{indexS.scan}.scanInfo(1).xOffset)
  xCTOffset = planC{indexS.scan}.scanInfo(1).xOffset;
  yCTOffset = planC{indexS.scan}.scanInfo(1).yOffset;
else
  xCTOffset = 0;
  yCTOffset = 0;
end

segOptS.xCTOffset = xCTOffset;
segOptS.yCTOffset = yCTOffset;

dummyM = zeros(segOptS.ROIImageSize);

segsM = planC{indexS.structures}(structNum).contour(sliceNum).segments;
numSegs = length(segsM);
maskM = dummyM;
mask3M = [];
segmentsM = [];

for k = 1 : numSegs
    
    pointsM = segsM(k).points;
    
    if ~isempty(pointsM)
        
        if ~size(pointsM, 1) < 4 %Since first == last by default, use 4.
            warning('A contour segment consists of less than 3 vertices, will not be rasterized.');
            continue;
        end
        
        str4 = ['Scan converting structure ' num2str(structNum) ', slice ' num2str(sliceNum) ', segment ' num2str(k) '.'];
        CERRStatusString(str4)
        
        [edgeM] = poly2Edges(pointsM(:,1:2),segOptS);  %convert from polygon to edge format
        
        [edge2M, flag2] = repairContour(edgeM, segOptS); %excision repair of self-intersecting contours
        
        [maskM] = scanPoly(edge2M, segOptS);    %convert edge information into zero-one mask
        zValue = pointsM(1,3);
        
        mask3M(:,:,k) = maskM;
        
    end
end

if ~isempty(mask3M)
    
    %Combine masks
    %Add segments together:
    %Any overlap is interpreted as a 'hole'
    baseM = dummyM;
    for m = 1 : size(mask3M,3)
        baseM = baseM + mask3M(:,:,m);  %to catalog overlaps
    end
    maskM = [baseM == 1];
    tmpM = mask2scan(maskM, segOptS, sliceNum);       %convert mask into scan segment format
    len = size(tmpM,1);
    zValuesV = ones(size(tmpM,1),1) * zValue;
    numSlices = length(planC{indexS.scan}.scanInfo);
    try    %%JOD, 16 Oct 03
        voxelThickness = planC{indexS.scan}.scanInfo(sliceNum).voxelThickness;
    catch
        voxelThicknessV = deduceVoxelThicknesses(planC);
        for p = 1 : length(voxelThicknessV)  %put back into planC
            planC{indexS.scan}.scanInfo(p).voxelThickness = voxelThicknessV(p);
        end
        voxelThickness = planC{indexS.scan}.scanInfo(sliceNum).voxelThickness;
    end
    thicknessV = ones(size(tmpM,1),1) * voxelThickness;
    segmentsM = [segmentsM; [zValuesV, tmpM, thicknessV]];
end

rS = segmentsM;
% 
% planC{indexS.structures}(i).rasterSegments = segmentsM;
% CERRStatusString('')
