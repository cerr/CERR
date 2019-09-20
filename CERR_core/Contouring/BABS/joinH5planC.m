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

%Undo resize
%mask3M = undoResizeMask(segMask3M,originImageSizV,rcsM,resizeMethod);
[minr, maxr, minc, maxc, mins, maxs] = getCropLimits(planC,[],scanNum,cropS);
limitsM = [minr, maxr, minc, maxc, mins, maxs];
if numel(minr)==1
    originImageSizV = [maxr-minr+1, maxc-minc+1, maxs-mins+1];
else
    originImageSizV = size(getScanArray(scanNum,planC));
end
[~, maskOut3M] = resizeScanAndMask([],segMask3M,originImageSizV,resizeMethod,limitsM);
origSizMask3M = false(size(getScanArray(scanNum,planC)));


for i = 1 : length(userOptS.strNameToLabelMap)
    
    temp = origSizMask3M;
    count = userOptS.strNameToLabelMap(i).value;
    maskForStr3M = maskOut3M == count;
    
    %Undo crop 
    temp(minr:maxr, minc:maxc, mins:maxs) = maskForStr3M;
    
    planC = maskToCERRStructure(temp, isUniform, scanNum, userOptS.strNameToLabelMap(i).structureName, planC);
    
end