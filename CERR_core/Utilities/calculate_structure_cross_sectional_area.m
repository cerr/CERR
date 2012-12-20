function areaV = calculate_structure_cross_sectional_area(structIndV,planC)
% function areaV = calculate_structure_cross_sectional_area(structIndV,planC)
%
% APA, 08/29/2012

if ~exist('planC','var')
    global planC
end
indexS = planC{end};

if ischar(structIndV)
    structIndV = {structIndV};
end
    
structureNamesC = {planC{indexS.structures}.structureName};
for i = 1:length(structIndV)    
    if isnumeric(structIndV(i))
        structNum = structIndV(i);
    else
        structureName = structIndV{i};
        structNum = getMatchingIndex(structureName,structureNamesC,'regex');
        if length(structNum) > 1
            structNum = structNum(1);
        end
    end
    
    if isempty(structNum) || length(structNum) > 1 
        areaV(i) = NaN;
        continue
    end
    
    [rasterSegments, planC, isError] = getRasterSegments(structNum,planC);
    if isempty(rasterSegments)
        areaV(i) = NaN;
        continue;
    end
    scanNum = getStructureAssociatedScan(structNum,planC);
    [~, uniqueSlices] = rasterToMask(rasterSegments, scanNum, planC);
    middleSlcNum = round(median(uniqueSlices));
    
    areaVal = 0;
    for segNum = 1:length(planC{indexS.structures}(structNum).contour(middleSlcNum).segments)
        areaVal = areaVal + polyarea(planC{indexS.structures}(structNum).contour(middleSlcNum).segments(segNum).points(:,1),planC{indexS.structures}(structNum).contour(middleSlcNum).segments(segNum).points(:,2));
    end
       
    areaV(i) = areaVal;
end

