function structM = findStructureMatrixForOneZSlice(allSegmentsM, zSliceUniformValue, CTOriginalZValues, CTSliceThickness, CTDeltaX, CTDeltaY, reusableZerosM)
%"findStructureMatrixForOneZSlice"
% returns structM, a matrix with 1's and 0's corresponding to
% the location of the points of a structure on a particular z slice.
%
% allSegmentsM = planC{indexS.structures}(structNum).rasterSegments;
% zSliceUniformValue = desired value of the z slice of the output matrix, structM
% CTOriginalZValues = [planC{indexS.scan}.scanInfo(:).zValue];
% reusableZerosM = an all-zero matrix the size of structM output.

structM = reusableZerosM;

%Test if structure is more than 1 full slice from the requested zSlice, if
%so return the all zero matrix, as the structure is not present.
maxStructureZVal = max(allSegmentsM(:,1));
minStructureZVal = min(allSegmentsM(:,1));
CTSpacing = CTOriginalZValues(2) - CTOriginalZValues(1);
if zSliceUniformValue < (minStructureZVal-CTSpacing) | zSliceUniformValue > (maxStructureZVal+CTSpacing)
    return
end
%END

%try to find a slice with the desired z value
if maxStructureZVal == minStructureZVal
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
  spaceToCranial = zSliceUniformValue - cranialZValue;
  spaceFromCaudal = caudalZValue - zSliceUniformValue;
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
    
    if spaceToCranial == 0
        structM = cranialM;
        return;
    end
    if spaceFromCaudal == 0
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
    
    structM = conv2(single(cranialM), weightsCranial/totalWeight, 'same') + conv2(single(caudalM), weightsCaudal/totalWeight, 'same');    
    structM = structM > .5;
    
end
  
