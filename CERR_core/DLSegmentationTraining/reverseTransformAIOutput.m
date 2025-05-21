function [dataOut4M,physExtentsV,scanNum,planC] = ...
    reverseTransformAIOutput(scanNum,data4M,userOptS,planC)
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
outputsC = fieldnames(userOptS.output);
output = outputsC{1};

%% Resize/pad mask to original dimensions

%Get parameters for resizing & cropping
cropS = scanOptS.crop; 
if ~isempty(cropS) && isfield(cropS(1),'params')
    for cropNum = 1:length(cropS)
        cropS(cropNum).params.saveStrToPlanCFlag = 0;
    end
end

% cropS.params.saveStrToPlanCFlag=0;
[minr, maxr, minc, maxc, slcV, ~, planC] = getCropLimits(planC,data4M,...
    scanNum,cropS);
scanArray3M = planC{indexS.scan}(scanNum).scanArray;
sizV = size(scanArray3M);
%dataOut3M = zeros(sizV, 'uint32');
dataOut4M = zeros([sizV,size(data4M,4)],class(data4M));
originImageSizV = [sizV(1:2), length(slcV)];
scanS = planC{indexS.scan}(scanNum);
[xValsV,yValsV,zValsV] = getScanXYZVals(scanS);
physExtentsV = [yValsV(minr),yValsV(maxr),...
    xValsV(minc),xValsV(maxc),...
    zValsV(slcV(1)),zValsV(slcV(end))];
%imgExtentsV = [minr,maxr,minc,maxc,slcV(1),slcV(end)];

%Undo resizing & cropping
resizeS = scanOptS.resize;

for nMethod = length(resizeS):-1:1

    resizeMethod = resizeS(nMethod).method;

    if isfield(resizeS(nMethod),'preserveAspectRatio') && ...
            strcmp(resizeS(nMethod).preserveAspectRatio,'Yes')
        preserveAspectFlag = 1;
    end

    if nMethod<length(resizeS)
        data4M = dataOut4M;
    end
    switch lower(resizeMethod)
        
        case 'pad2d'
            
            limitsM = [minr, maxr, minc, maxc];
            resizeMethod = 'unpad2d';
            originImageSizV = [sizV(1:2), length(slcV)];
            if strcmpi(output, 'labelmap')                
                %dataOut4M = zeros(sizV,, 'uint32');
                [~, dataOut4M(:,:,slcV,:)] = ...
                    resizeScanAndMask([],data4M,originImageSizV,...
                    resizeMethod,limitsM);                
            else
                [dataOut4M(:,:,slcV,:),~] = ...
                    resizeScanAndMask(data4M,[],originImageSizV,...
                    resizeMethod,limitsM);                
            end
            
        case 'pad3d'
            resizeMethod = 'unpad3d';
            [~, tempData4M] = ...
                resizeScanAndMask([],data4M,sizV,resizeMethod);
            dataOut4M(:,:,slcV,:) = tempData4M;

        case 'padorcrop3d'
            resizeMethod = 'padorcrop3d';
            [~, tempData4M] = ...
                resizeScanAndMask([],data4M,sizV,resizeMethod);
            dataOut4M(:,:,slcV,:) = tempData4M;

        case 'padorcrop2d'
            resizeMethod = 'padorcrop2d';
            limitsM = [minr, maxr, minc, maxc];
            originImageSizV = [sizV(1:2), length(slcV)];
            [~, dataOut4M(:,:,slcV,:)] = ...
                resizeScanAndMask([],data4M,originImageSizV,...
                resizeMethod,limitsM);

        case 'padslices'
            resizeMethod = 'unpadslices';
            [~, dataOut4M] = ...
                resizeScanAndMask([],data4M,originImageSizV(3),...
                resizeMethod);

        case { 'bilinear', 'sinc', 'bicubic'}
            dataOut4M = zeros([sizV,size(data4M,4)], class(data4M));
            limitsM = [minr, maxr, minc, maxc];

            outSizeV = [maxr-minr+1,maxc-minc+1,originImageSizV(3)];
            if strcmpi(output,'labelmap')
                % resize currData3M using nearest neighbor interpolation
                [~,tempData4M] = ...
                    resizeScanAndMask([],data4M,outSizeV,'nearest',...
                    limitsM,preserveAspectFlag);
            else
                tempData4M = ...
                    resizeScanAndMask(data4M,[],outSizeV,resizeMethod,...
                    limitsM,preserveAspectFlag);
            end

            if size(limitsM,1)>1
                %2-D resize methods
                dataOut4M(:,:,slcV,:) = tempData4M;
            else
                %3-D resize methods
                dataOut4M(minr:maxr, minc:maxc, slcV, :) = tempData4M;
            end

        case 'none'
            dataOut4M(minr:maxr,minc:maxc,slcV,:) = data4M;
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
        [~,dataOut4M] = resampleScanAndMask([],double(dataOut4M),xValsV,...
            yValsV,zValsV,xVals0V,yVals0V,zVals0V);
    else
        dataOut4M = resampleScanAndMask(double(dataOut4M),[],xValsV,...
            yValsV,zValsV,xVals0V,yVals0V,zVals0V);
    end

    scanNum = origScanNum;
end


end