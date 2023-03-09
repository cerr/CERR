function [dataOut3M,scanNum,planC] = reverseTransformAIOutput(scanNum,data3M,...
                             userOptS,planC)
% Undo pre-processing transformations (cropping, resampling, registration)
% AI 09/01/22

if ~exist('planC','var')
    global planC
end
indexS = planC{end};

isUniform = 0;
preserveAspectFlag = 0;
scanOptS = userOptS.input.scan(scanNum);

%% Get output type
output = userOptS.output;

%% Resize/pad mask to original dimensions

%Get parameters for resizing & cropping
cropS = scanOptS.crop; 
if ~isempty(cropS) && isfield(cropS(1),'params')
    for cropNum = 1:length(cropS)
        cropS(cropNum).params.saveStrToPlanCFlag = 0;
    end
end

% cropS.params.saveStrToPlanCFlag=0;
[minr, maxr, minc, maxc, slcV, ~, planC] = getCropLimits(planC,data3M,...
    scanNum,cropS);
scanArray3M = planC{indexS.scan}(scanNum).scanArray;
sizV = size(scanArray3M);
%dataOut3M = zeros(sizV, 'uint32');
dataOut3M = zeros(sizV,class(data3M));
originImageSizV = [sizV(1:2), length(slcV)];

%Undo resizing & cropping
resizeS = scanOptS.resize;

for nMethod = length(resizeS):-1:1

    resizeMethod = resizeS(nMethod).method;

    if isfield(resizeS(nMethod),'preserveAspectRatio') && ...
            strcmp(resizeS(nMethod).preserveAspectRatio,'Yes')
        preserveAspectFlag = 1;
    end

    if nMethod<length(resizeS)
        data3M = dataOut3M;
    end
    switch lower(resizeMethod)

        case 'pad2d'

            dataOut3M = zeros(sizV, 'uint32');
            limitsM = [minr, maxr, minc, maxc];
            resizeMethod = 'unpad2d';
            originImageSizV = [sizV(1:2), length(slcV)];
            [~, dataOut3M(:,:,slcV)] = ...
                resizeScanAndMask([],data3M,originImageSizV,...
                resizeMethod,limitsM);

        case 'pad3d'
            resizeMethod = 'unpad3d';
            [~, tempData3M] = ...
                resizeScanAndMask([],data3M,sizV,resizeMethod);
            dataOut3M(:,:,slcV) = tempData3M;

        case 'padorcrop3d'
            resizeMethod = 'padorcrop3d';
            [~, tempData3M] = ...
                resizeScanAndMask([],data3M,sizV,resizeMethod);
            dataOut3M(:,:,slcV) = tempData3M;

        case 'padorcrop2d'
            resizeMethod = 'padorcrop2d';
            limitsM = [minr, maxr, minc, maxc];
            originImageSizV = [sizV(1:2), length(slcV)];
            [~, dataOut3M(:,:,slcV)] = ...
                resizeScanAndMask([],data3M,originImageSizV,...
                resizeMethod,limitsM);

        case 'padslices'
            resizeMethod = 'unpadslices';
            [~, dataOut3M] = ...
                resizeScanAndMask([],data3M,originImageSizV(3),...
                resizeMethod);

        case { 'bilinear', 'sinc', 'bicubic'}
            dataOut3M = zeros(sizV, 'uint32');
            limitsM = [minr, maxr, minc, maxc];

            outSizeV = [maxr-minr+1,maxc-minc+1,originImageSizV(3)];
            if strcmpi(output,'labelmap')
                % resize currData3M using nearest neighbor interpolation
                [~,tempData3M] = ...
                    resizeScanAndMask([],data3M,outSizeV,resizeMethod,...
                    limitsM,preserveAspectFlag);
            else
                % resize currData3M using nearest neighbor interpolation
                tempData3M = ...
                    resizeScanAndMask(data3M,[],outSizeV,resizeMethod,...
                    limitsM,preserveAspectFlag);
            end

            if size(limitsM,1)>1
                %2-D resize methods
                dataOut3M(:,:,slcV) = tempData3M;
            else
                %3-D resize methods
                dataOut3M(minr:maxr, minc:maxc, slcV) = tempData3M;
            end

        case 'none'
            dataOut3M(minr:maxr,minc:maxc,slcV) = data3M;
    end
end

%% Resample to original resolution
resampleS = scanOptS.resample;
if ~strcmpi(resampleS.method,'none')
    fprintf('\n Resampling output...\n');
    % Get the new x,y,z grid
    [xValsV, yValsV, zValsV] = getScanXYZVals(planC{indexS.scan}(scanNum));
    if yValsV(1) > yValsV(2)
        yValsV = fliplr(yValsV);
    end
    %Get original grid
    origScanNum = scanOptS.origScan;
    [xVals0V, yVals0V, zVals0V] = getScanXYZVals(planC{indexS.scan}(origScanNum));
    if yVals0V(1) > yVals0V(2)
        yVals0V = fliplr(yVals0V);
    end

    if strcmpi(output,'labelmap')
        %Resample mask ('nearest' interpolation)
        [~,dataOut3M] = resampleScanAndMask([],double(dataOut3M),xValsV,...
            yValsV,zValsV,xVals0V,yVals0V,zVals0V);
    else
        dataOut3M = resampleScanAndMask(double(dataOut3M),[],xValsV,...
            yValsV,zValsV,xVals0V,yVals0V,zVals0V);
    end

    scanNum = origScanNum;
end


end

