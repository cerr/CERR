function planC  = joinH5planC(scanNum,segMask3M,userOptS,planC)
% function planC  = joinH5planC(scanNum,segMask3M,userOptS,planC)


if ~exist('planC','var')
    global planC
end
indexS = planC{end};

isUniform = 0;
preserveAspectFlag = 0;

%% Resize/pad mask to original dimensions
scanOptS = userOptS(scanNum).scan;

%Get parameters for resizing & cropping
resizeMethod = scanOptS(scanNum).resize.method;
cropS = scanOptS(scanNum).crop; %Added
if isfield(scanOptS(scanNum).resize,'preserveAspectRatio')
    if strcmp(scanOptS(scanNum).resize.preserveAspectRatio,'Yes')
        preserveAspectFlag = 1;
    end
end
% cropS.params.saveStrToPlanCFlag=0;
[minr, maxr, minc, maxc, slcV, planC] = getCropLimits(planC,segMask3M,...
    scanNum,cropS);
scanArray3M = planC{indexS.scan}(scanNum).scanArray;
sizV = size(scanArray3M);
maskOut3M = zeros(sizV, 'uint32');
originImageSizV = [sizV(1:2), length(slcV)];

%Undo resizing & cropping
switch lower(resizeMethod)
    
    case 'pad2d'
        limitsM = [minr, maxr, minc, maxc];
        resizeMethod = 'unpad2d';
        originImageSizV = [sizV(1:2), length(slcV)];
        [~, maskOut3M(:,:,slcV)] = ...
            resizeScanAndMask(segMask3M,segMask3M,originImageSizV,...
            resizeMethod,limitsM);
        
    case 'pad3d'
        resizeMethod = 'unpad3d';
        [~, tempMask3M] = ...
            resizeScanAndMask([],segMask3M,sizV,resizeMethod);
        maskOut3M(:,:,slcV) = tempMask3M;
        
    otherwise
        limitsM = [minr, maxr, minc, maxc];
        
        [~,tempMask3M] = ...
            resizeScanAndMask([],segMask3M,originImageSizV,resizeMethod,...
            limitsM,preserveAspectFlag);
        
        if size(limitsM,1)>1
            %2-D resize methods
            maskOut3M(:,:,slcV) = tempMask3M;
        else
            %3-D resize methods
            maskOut3M(minr:maxr, minc:maxc, slcV) = tempMask3M;
        end
end


for i = 1 : length(userOptS.strNameToLabelMap)
    
    labelVal = userOptS.strNameToLabelMap(i).value;
    maskForStr3M = maskOut3M == labelVal;
    planC = maskToCERRStructure(maskForStr3M, isUniform, scanNum,...
        userOptS.strNameToLabelMap(i).structureName, planC);
    
end

end