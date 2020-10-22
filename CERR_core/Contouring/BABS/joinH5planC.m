function planC  = joinH5planC(scanNum,segMask3M,userOptS,planC)
% function planC  = joinH5planC(scanNum,segMask3M,userOptS,planC)

if ~exist('planC','var')
    global planC
end
indexS = planC{end};

isUniform = 0;
preserveAspectFlag = 0;
scanOptS = userOptS(scanNum).scan;

%% Resize/pad mask to original dimensions
%Get parameters for resizing & cropping
resizeMethod = scanOptS.resize.method;
cropS = scanOptS.crop; %Added
if isfield(scanOptS.resize,'preserveAspectRatio')
    if strcmp(scanOptS.resize.preserveAspectRatio,'Yes')
        preserveAspectFlag = 1;
    end
end
% cropS.params.saveStrToPlanCFlag=0;
[minr, maxr, minc, maxc, slcV, ~, planC] = getCropLimits(planC,segMask3M,...
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

%% Resample to original resolution
resampleS = scanOptS.resample;
if ~strcmpi(resampleS.method,'none')
    fprintf('\n Resampling masks...\n');
    % Get the new x,y,z grid
    [xValsV, yValsV, zValsV] = getScanXYZVals(planC{indexS.scan}(scanNum));
    if yValsV(1) > yValsV(2)
        yValsV = fliplr(yValsV);
    end
    %Get input scan & resolution
    dx = median(diff(xValsV));
    dy = median(diff(yValsV));
    dz = median(diff(zValsV));
    inputResV = [dx,dy,dz];
    %Get original resolution
    origScanNum = scanOptS.origScan;
    [xVals0V, yVals0V, zVals0V] = getScanXYZVals(planC{indexS.scan}(origScanNum));
    if yVals0V(1) > yVals0V(2)
        yVals0V = fliplr(yVals0V);
    end
    dx0 = median(diff(xVals0V));
    dy0 = median(diff(yVals0V));
    if isfield(userOptS(scanNum).scan.resample,'resolutionZCm')
        dz0 = median(diff(zVals0V));
        zValsV = zVals0V;
    else
        dz0 = nan;
    end
    outResV = [dx0,dy0,dz0];
    %Resample
    %maskOut3M = imgResample3d(double(maskOut3M),inputResV,xValsV,yValsV,...
    %   zValsV,outResV,'nearest',0);
    gridResampleMethod = 'center';
    volumeResampleMethod = 'nearest';
    %[xResampleV,yxResampleV,zResampleV] = ...
    %    getResampledGrid(outResV,xValsV,yValsV,zValsV,gridResampleMethod);
      maskOut3M = imgResample3d(double(maskOut3M),...
                              xValsV,yValsV,zValsV,...
                              xVals0V, yVals0V, zVals0V,...
                              volumeResampleMethod);
                                
    scanNum = origScanNum;
end

for i = 1 : length(userOptS(scanNum).strNameToLabelMap)
    
    labelVal = userOptS(scanNum).strNameToLabelMap(i).value;
    maskForStr3M = maskOut3M == labelVal;
    planC = maskToCERRStructure(maskForStr3M, isUniform, scanNum,...
        userOptS(scanNum).strNameToLabelMap(i).structureName, planC);
    
end

end