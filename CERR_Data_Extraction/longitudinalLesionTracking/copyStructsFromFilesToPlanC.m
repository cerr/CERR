function planC = copyStructsFromFilesToPlanC(scanFileNames, planC)
% function planC = copyStructsFromFilesToPlanC(scanFileNames, planC)
%
% APA 07/17/2013

if ~exist('planC','var')
    global planC
end

indexS = planC{end};

[xValsBase, yValsBase, zValsBase] = getScanXYZVals(planC{indexS.scan});

for scanFileIndex = length(scanFileNames)
    scanBasePlanC = loadPlanC(scanFileNames{scanFileIndex},tempdir);
    indexSbaseScan = scanBasePlanC{end};
    annotROIIndV = strmatch('Annotation ROI',{scanBasePlanC{indexSbaseScan.structures}.structureName});
    annotStrV = find(annotROIIndV);
    [xValsBase1, yValsBase1, zValsBase1] = getScanXYZVals(scanBasePlanC{indexSbaseScan.scan});
    for structIndex = 1:length(annotStrV)
        structNum = annotStrV(structIndex);
        sliceNumsV = [];
        clear pointsC
        for sliceNum = 1:length(scanBasePlanC{indexSbaseScan.structures}(structNum).contour)
            for segNum = 1:length(scanBasePlanC{indexSbaseScan.structures}(structNum).contour(sliceNum).segments)
                points = scanBasePlanC{indexSbaseScan.structures}(structNum).contour(sliceNum).segments(segNum).points;
                if ~isempty(points)
                    zValue = points(1,3);
                    newSliceNum = findnearest(zValsBase,zValue);
                    sliceNumsV = [sliceNumsV newSliceNum];
                    points(:,3) = zValsBase(newSliceNum);
                    pointsC{newSliceNum} = points;
                end
            end
        end
        
        [sliceNumsV, indUniq] = unique(sliceNumsV);
        
        % Create Structures segments on sacn slices
        newStructS = newCERRStructure(1, planC);
        for slcNum = 1:length(zValsBase)
            if ismember(slcNum,sliceNumsV)
                newStructS.contour(slcNum).segments(1).points = pointsC{slcNum};
            else
                newStructS.contour(slcNum).segments.points = [];
            end
        end
        
        newStructNum = length(planC{indexS.structures}) + 1;
        newStructS.structureName = 'Annotation ROI';
        
        planC{indexS.structures} = dissimilarInsert(planC{indexS.structures}, newStructS, newStructNum);
        planC = getRasterSegs(planC, newStructNum);
        planC = updateStructureMatrices(planC, newStructNum, sliceNumsV);
    end
end

