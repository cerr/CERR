function medianArea = calcMedianSurfaceArea(strNumV,planC)

if ~exist('planC','var')
    global planC
end

if ~iscell(planC)
    fullFname = planC;
    planC = loadPlanC(fullFname, tempdir);    
    planC = quality_assure_planC(fullFname, planC);    
end

indexS = planC{end};

scanNum = getStructureAssociatedScan(strNumV(1),planC);

uniqSlcV = [];
for i = 1:length(strNumV)
    [rasterSegments, planC, isError] = getRasterSegments(strNumV(i),planC);
    [~, uniqueSlices] = rasterToMask(rasterSegments, scanNum, planC);
    uniqSlcV = [uniqSlcV; uniqueSlices];
end

uniqSlcV = unique(uniqSlcV);

[xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(scanNum));
dx = abs(mean(diff(xV)));
dy = abs(mean(diff(yV)));
voxelArea = dx*dy;
areaV = zeros(length(uniqSlcV),1);
for i = 1:length(uniqSlcV)
    gauss2M = imgaussfilt(planC{indexS.scan}(scanNum).scanArray(:,:,uniqSlcV(i)),4);
    areaV(i) = sum(gauss2M(:) > 400)*voxelArea;
end

medianArea = median(areaV);

