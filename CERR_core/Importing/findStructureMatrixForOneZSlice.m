function structM = findStructureMatrixForOneZSlice(allSegmentsM, zSliceUniformValue, CTOriginalZValues, CTSliceThickness, CTDeltaX, CTDeltaY, reusableZerosM)
%"findStructureMatrixForOneZSlice"
% returns structM, a matrix with 1's and 0's corresponding to
% the location of the points of a structure on a particular z slice.
%
% allSegmentsM = planC{indexS.structures}(structNum).rasterSegments;
% zSliceUniformValue = desired value of the z slice of the output matrix, structM
% CTOriginalZValues = [planC{indexS.scan}.scanInfo(:).zValue];
% reusableZerosM = an all-zero matrix the size of structM output.
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

structM = reusableZerosM;

%Test if structure is more than 1 full slice from the requested zSlice, if
%so return the all zero matrix, as the structure is not present.
maxStructureZVal = max(allSegmentsM(:,1));
minStructureZVal = min(allSegmentsM(:,1));
if numel(CTOriginalZValues) == 1 % for single slice scans
    CTSpacing = 1;
else
    CTSpacing = CTOriginalZValues(2) - CTOriginalZValues(1);
end
if (zSliceUniformValue < (minStructureZVal-CTSpacing/2)) || (zSliceUniformValue > (maxStructureZVal+CTSpacing/2))    % APA Q: is CTSpacing correct for max check?
    return
end
%END

%try to find a slice with the desired z value
if maxStructureZVal==minStructureZVal
    indV = 1:size(allSegmentsM,1);
else
    indV = find(abs(allSegmentsM(:,1) - zSliceUniformValue) < 0.001);  %mask values on this slice
end
if ~isempty(indV) %no need to interpolate
  segmentsM = allSegmentsM(indV(:),7:9);     %segments
  for i = 1 : size(segmentsM,1)
    structM(segmentsM(i,1),segmentsM(i,2):segmentsM(i,3)) = 1;
  end
else %simple interpolation necessary
  %find the two slices closest to this uniform z value
  cranialSlice = max(find(CTOriginalZValues < zSliceUniformValue));
  caudalSlice  = min(find(CTOriginalZValues >= zSliceUniformValue));
  if isempty(cranialSlice)
    cranialSlice = caudalSlice;
  end
  if isempty(caudalSlice)
    caudalSlice = cranialSlice;
  end
  cranialZValue = CTOriginalZValues(cranialSlice);
  caudalZValue  = CTOriginalZValues(caudalSlice);
  
  sliceSpacing = caudalZValue - cranialZValue;
  if sliceSpacing ~=0
      spaceToCranial = zSliceUniformValue - cranialZValue;
      spaceFromCaudal = caudalZValue - zSliceUniformValue;
  else
      spaceToCranial = 0 ;
      spaceFromCaudal = 0 ;
  end
  
%   cranialIsNearest = spaceFromCaudal >= spaceToCranial;
  
  %If we are within the valid slice thickness of either slice, no need to
  %interpolate.
%   closeEnough = (spaceToCranial < (CTSliceThickness(cranialSlice)/2) | (spaceFromCaudal < (CTSliceThickness(caudalSlice)/2)));
  
  %note:  we don't really need the farther matrices except for the else of closeEnough, so speed could be optimized here.
  indCranial = find(abs(allSegmentsM(:,1) - cranialZValue) < 0.001);  %mask values on this slice
  indCaudal = find(abs(allSegmentsM(:,1) - caudalZValue ) < 0.001);  %mask values on this slice
  
  segmentsCranialM = allSegmentsM(indCranial(:),7:9);     %segments
  segmentsCaudalM = allSegmentsM(indCaudal(:),7:9);     %segments
%   if closeEnough & cranialIsNearest %use cranial
%     for i = 1 : size(segmentsCranialM,1)
%       structM(segmentsCranialM(i,1),segmentsCranialM(i,2):segmentsCranialM(i,3)) = 1;
%     end
%   elseif closeEnough & ~cranialIsNearest %use caudal
%     for i = 1 : size(segmentsCaudalM,1)
%       structM(segmentsCaudalM(i,1),segmentsCaudalM(i,2):segmentsCaudalM(i,3)) = 1;
%     end
%   else %do some interpolation
    cranialM = reusableZerosM;
    caudalM  = reusableZerosM;
    for i = 1 : size(segmentsCranialM,1)
      cranialM(segmentsCranialM(i,1),segmentsCranialM(i,2):segmentsCranialM(i,3)) = 1;
    end
    for i = 1:size(segmentsCaudalM,1)
      caudalM(segmentsCaudalM(i,1),segmentsCaudalM(i,2):segmentsCaudalM(i,3)) = 1;
    end
       
    if spaceToCranial < 1e-6
        structM = cranialM;
        return;
    end
    if spaceFromCaudal < 1e-6
        structM = caudalM;
        return;        
    end    
    
    %Interpolate using distance weighting.  Points interpolated to .5 or
    %greater are on.
    
    distanceToCranialRegion = spaceToCranial;
    distanceToCaudalRegion  = spaceFromCaudal;    
    
    %Distance from middle point to diagonal neighbor in plane.
    diagDist = sqrt(CTDeltaX^2 + CTDeltaY^2);
    inPlaneNeighborsDistance = [diagDist CTDeltaY diagDist;CTDeltaX 0 CTDeltaX;diagDist CTDeltaY diagDist];
    distToCranialNeighbors = sqrt(inPlaneNeighborsDistance.^2 + distanceToCranialRegion^2);
    distToCaudalNeighbors  = sqrt(inPlaneNeighborsDistance.^2 + distanceToCaudalRegion^2);    
    
    weightsCranial = 1./distToCranialNeighbors;
    weightsCaudal  = 1./distToCaudalNeighbors;
    totalWeight = sum([sum(weightsCranial(:)), sum(weightsCaudal(:))]);
    
    structM = conv2(double(cranialM), weightsCranial/totalWeight, 'same') + conv2(double(caudalM), weightsCaudal/totalWeight, 'same');  
%     % Calculate threshold
%     %a = 0.5*(distanceToCranialRegion + distanceToCaudalRegion);
%     a =  0.5*sliceSpacing ;
%     b = sqrt(CTDeltaX^2 + a^2);
%     c = sqrt(CTDeltaX^2 + CTDeltaY^2 + a^2);
%     cutoff = (1/a)/(1/a + 4/b + 4/c);
%     structM = structM > cutoff;
    structM = structM > .5;  % APA: Causes trouble for structures with
    % sparse points
    % structM = structM ~= 0; % APA: All points selected    
end  