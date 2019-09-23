function planC  = joinH5planC(segMask3M,userOptS,planC)
% function planC  = joinH5planC(segMask3M,userOptS,planC)
%

if ~exist('planC','var')
    global planC
end
indexS = planC{end};

resizeMethod = userOptS.resize.method;
cropS = userOptS.crop; %Added

scanNum = 1;
isUniform = 0;
%save structures segmented to planC


% Get mask3M from outline/shoulder crop?
testFlag = 1;
[scanC, mask3M] = extractAndPreprocessDataForDL(userOptS,planC,testFlag);

%Undo resize
% mask3M = undoResizeMask(segMask3M,originImageSizV,rcsM,resizeMethod);
[minr, maxr, minc, maxc, mins, maxs] = getCropLimits(planC,mask3M,scanNum,cropS);
limitsM = [minr, maxr, minc, maxc];

scanArray3M = planC{indexS.scan}(scanNum).scanArray;
sizV = size(scanArray3M);
maskOut3M = zeros(sizV, 'uint32');

if length(minr) > 1
    [~, maskOut3M(:,:,mins:maxs)] = resizeScanAndMask(segMask3M,segMask3M,sizV(1:2),resizeMethod,limitsM);
else
    [~, maskOut3M(minr:maxr, minc:maxc, mins:maxs)] = resizeScanAndMask(segMask3M,segMask3M,sizV(1:2),resizeMethod,limitsM);
end

for i = 1 : length(userOptS.strNameToLabelMap)
    
    labelVal = userOptS.strNameToLabelMap(i).value;
    maskForStr3M = maskOut3M == labelVal;        
    planC = maskToCERRStructure(maskForStr3M, isUniform, scanNum, userOptS.strNameToLabelMap(i).structureName, planC);
    
end