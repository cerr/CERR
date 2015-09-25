function planC = createUniformlySlicedPlanC(planC)
%
% function planC = createUniformlySlicedPlanC(planC)
%
% This function creates uniformly sliced planC 
%
% APA, 08/19/2011

global planC

indexS = planC{end};

% Get scan grid
zValuesV = [planC{indexS.scan}.scanInfo(:).zValue];
zDiffV = diff(zValuesV);
if ~all(zDiffV == min(zDiffV))
   % Create new z-vector
   minSpac = min(zDiffV);
   zValNewV = zValuesV(1):minSpac:zValuesV(end);
   
else
    % Already uniform plan
    return
    
end


% Loop over new z-values and create new scanArray
numSlices = length(zValNewV);

scanInfoS = planC{indexS.scan}.scanInfo(1);
scanInfoS.sliceThickness = minSpac;
scanInfoS.voxelThickness = minSpac;

for i = 1:numSlices
    
    % Find the nearest non-uniform slice
    nearestZindexV(i) = findnearest(zValuesV,zValNewV(i));
    
    scanArrayNewM(:,:,i) = planC{indexS.scan}.scanArray(:,:,nearestZindexV(i));
    
    scanInfoS.zValue = zValNewV(i);
    
    newScanInfoS(i) = scanInfoS;
    
end


planC{indexS.scan}.scanArray = scanArrayNewM;

clear scanArrayNewM;

planC{indexS.scan}.scanInfo = newScanInfoS;


% Change structure z-cords
numStructures = planC{indexS.structures};
for strNum = 1:length(numStructures)
    
    newStructureS = planC{indexS.structures}(strNum);
    
    newStructureS.numberOfScans = numSlices;
    
    newStructureS.contour(:) = [];
    newStructureS.contour
    newStructureS.contour(1:numSlices) = planC{indexS.structures}(strNum).contour(nearestZindexV);
    
    for slcNum = 1:length(newStructureS.contour)
        
        for segNum = 1:length(newStructureS.contour(slcNum).segments)
            
            if ~isempty(newStructureS.contour(slcNum).segments(segNum).points)
            
                newStructureS.contour(slcNum).segments(segNum).points(:,3) = zValNewV(slcNum);
            
            end
            
        end
        
    end
    
    planC{indexS.structures}(strNum) = newStructureS;
    
    
end


% ReRaster and Uniformize

reRasterAndUniformize;


