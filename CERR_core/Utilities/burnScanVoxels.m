function planC = burnScanVoxels(scanNum,structNumV,doseNum,isodoseLevelV,planC)
% function burnScanVoxels(scanNum,structNumV,doseNum,isodoseLevelV,planC)
%
% This function burns-in the scan with structure boundary and isodose.
%
% APA, 7/9/2021

if ~exist('planC','var')
    global planC
end
indexS = planC{end};

scanArray3M = planC{indexS.scan}(scanNum).scanArray;
maxScanVal = max(scanArray3M(:));
burnInVal = maxScanVal + 100;

for iStr = 1:length(structNumV)
    
    strNum = structNumV(iStr);
    
    % Get Structure mask
    mask3M = getStrMask(strNum,planC);
    
    % Get surface points of structure
    surfPoints = getSurfacePoints(mask3M);
    surf3M = false(size(mask3M));
    for i=1:size(surfPoints,1)
        surf3M(surfPoints(i,1),surfPoints(i,2), surfPoints(i,3)) = 1;
    end
    
    % burn-in
    scanArray3M(surf3M) = burnInVal;
end

for iLevel = 1:length(isodoseLevelV)
    
    doseLevel = isodoseLevelV(iLevel);
    
    % Convert isodose levels to structures
    planC = doseToStruct(doseNum,doseLevel,scanNum,planC);
    
    strNum = length(planC{indexS.structures});
    
    % Get mask for the isodose structures
    mask3M = getStrMask(strNum,planC);
    
    % Get surface points of isodose structures
    surfPoints = getSurfacePoints(mask3M);
    surf3M = false(size(mask3M));
    for i=1:size(surfPoints,1)
        surf3M(surfPoints(i,1),surfPoints(i,2), surfPoints(i,3)) = 1;
    end
    
    % burn-in
    scanArray3M(surf3M) = burnInVal;
    
    % Delete isodose structure
    planC = deleteStructure(planC,strNum);
 
end

planC{indexS.scan}(scanNum).scanArray = scanArray3M;
