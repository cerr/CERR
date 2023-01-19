function [volToEval,maskBoundingBox3M,gridS,paramS,diagS] = ...
    preProcessForRadiomics(scanNum,structNum, paramS, planC)
% preProcessForRadiomics.m
% Pre-process image for radiomics feature extraction. Includes
% perturbation, resampling, cropping, and intensity-thresholding.
%
% AI 3/28/19



%% Get scan array, mask and x,y,z grid for reslicing
if numel(scanNum) == 1
    
    if ~exist('planC','var')
        global planC
    end
    
    indexS = planC{end};
        
    % Get scan
    scanArray3M = getScanArray(planC{indexS.scan}(scanNum));
    scanArray3M = double(scanArray3M) - ...
        planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;
    
    scanSiz = size(scanArray3M);
    
    if numel(structNum) == 1
        % Get structure mask
        [rasterSegments] = getRasterSegments(structNum,planC);
        [maskUniq3M, uniqueSlices] = rasterToMask(rasterSegments, scanNum, planC);
        mask3M = false(scanSiz);
        mask3M(:,:,uniqueSlices) = maskUniq3M;
    else
        mask3M = structNum;
    end
    
    % Get x,y,z grid for reslicing and calculating the shape features
    [xValsV, yValsV, zValsV] = getScanXYZVals(planC{indexS.scan}(scanNum));
    if yValsV(1) > yValsV(2)
        yValsV = fliplr(yValsV);
    end
    %zValsV = zValsV(uniqueSlices);
    
%     % Get image types with various parameters
%     fieldNamC = fieldnames(paramS.imageType);
%     for iImg = 1:length(fieldNamC)
%         for iFilt = 1:length(paramS.imageType.(fieldNamC{iImg}))
%             imageType = fieldNamC{iImg};
%             if strcmpi(imageType,'SUV')
%                 scanInfoS = planC{indexS.scan}(scanNum).scanInfo;
%                 paramS.imageType.(fieldNamC{iImg})(iFilt).scanInfoS = scanInfoS;
%             end
%         end
%     end
    
else
    
    scanArray3M = scanNum;
    mask3M = structNum;
    
    % Assume xValsV,yValsV,zValsV increase monotonically.
    xValsV = planC{1};
    yValsV = planC{2};
    zValsV = planC{3};
    
end

if isempty(scanArray3M)
    volToEval = [];
    maskBoundingBox3M = [];
    gridS = [];
    return;
end

% Pixelspacing (dx,dy,dz)
PixelSpacingX = abs(xValsV(1) - xValsV(2));
PixelSpacingY = abs(yValsV(1) - yValsV(2));
PixelSpacingZ = abs(zValsV(1) - zValsV(2));

diagS.numVoxelsOrig = sum(mask3M(:));

%% Apply global settings
whichFeatS = paramS.whichFeatS;

perturbX = 0;
perturbY = 0;
perturbZ = 0;

%--- 1. Perturbation ---
if whichFeatS.perturbation.flag
    
    [scanArray3M,mask3M] = perturbImageAndSeg(scanArray3M,mask3M,planC,...
        scanNum,whichFeatS.perturbation.sequence,...
        whichFeatS.perturbation.angle2DStdDeg,...
        whichFeatS.perturbation.volScaleStdFraction,...
        whichFeatS.perturbation.superPixVol);
    
    % Get grid perturbation deltas
    if ismember('T',whichFeatS.perturbation.sequence)
        perturbFractionV = [-0.75,-0.25,0.25,0.75];
        perturbFractionV(randsample(4,1));
        perturbX = PixelSpacingX*perturbFractionV(randsample(4,1));
        perturbY = PixelSpacingY*perturbFractionV(randsample(4,1));
        perturbZ = PixelSpacingZ*perturbFractionV(randsample(4,1));
    end
    
end


%--- 2. Crop scan around mask and pad as required ---
padScaleX = 1;
padScaleY = 1;
padScaleZ = 1;
if whichFeatS.resample.flag
    dx = median(diff(xValsV));
    dy = median(diff(yValsV));
    dz = median(diff(zValsV));
    padScaleX = ceil(whichFeatS.resample.resolutionXCm/dx);
    padScaleY = ceil(whichFeatS.resample.resolutionYCm/dy);
    padScaleZ = ceil(whichFeatS.resample.resolutionZCm/dz);
end

%Default:Pad by 5 voxels (original image intensities) before resampling
padMethod = 'expand';
padSizV = [5,5,5];
if whichFeatS.padding.flag
    if isfield(whichFeatS.padding,'size')
        filtPadSizV = whichFeatS.padding.size;
        filtPadSizV = reshape(filtPadSizV,1,[]);
        if length(filtPadSizV)==2
            filtPadSizV = [filtPadSizV,0];
        end
        filtPadSizV = filtPadSizV.*[padScaleX padScaleY padScaleZ];
        repIdxV = filtPadSizV > padSizV;
        padSizV(repIdxV) = filtPadSizV(repIdxV);
    end
end

% Crop to ROI and pad
%cropFlag = 1;
%padMethod = whichFeatS.padding.method;
%---For IBSI2 ------
cropFlag = 0;
padMethod = 'none';
%------------------
scanArray3M = double(scanArray3M);
[padScanBoundsForResamp3M,padMaskBoundsForResamp3M,outLimitsV] = ...
    padScan(scanArray3M,mask3M,padMethod,padSizV,cropFlag);
xValsV = xValsV(outLimitsV(3):outLimitsV(4));
yValsV = yValsV(outLimitsV(1):outLimitsV(2));
zValsV = zValsV(outLimitsV(5):outLimitsV(6));
slcIndV = outLimitsV(5):outLimitsV(6);

%--- 3. Resampling ---

%Get resampling method
if whichFeatS.resample.flag
    % Pixelspacing (dx,dy,dz) after resampling
    if ~isempty(whichFeatS.resample.resolutionXCm)
        PixelSpacingX = whichFeatS.resample.resolutionXCm;
    end
    if ~isempty(whichFeatS.resample.resolutionYCm)
        PixelSpacingY = whichFeatS.resample.resolutionYCm;
    end
    if ~isempty(whichFeatS.resample.resolutionZCm)
        PixelSpacingZ = whichFeatS.resample.resolutionZCm;
    end
    
    % Interpolate using the method defined in settings file
    roiInterpMethod = 'linear';
    scanInterpMethod = whichFeatS.resample.interpMethod;
    extrapVal = 0;
    gridResampleMethod = 'center';
    
    % Interpolate using the method defined in settings file
    origVolToEval = padScanBoundsForResamp3M;
    origMask = padMaskBoundsForResamp3M;
    outputResV = [PixelSpacingX,PixelSpacingY,PixelSpacingZ];
    originV = [xValsV(1),yValsV(1),zValsV(end)];
    
    %Get resampling grid 
    [xResampleV,yResampleV,zResampleV] = getResampledGrid(outputResV,...
        xValsV,yValsV,zValsV,originV,gridResampleMethod,...
        [perturbX,perturbY,perturbZ]);

    %Resample scan
    resampScanBounds3M = imgResample3d(origVolToEval,xValsV,yValsV,zValsV,...
        xResampleV,yResampleV,zResampleV,scanInterpMethod,extrapVal);
    %Option to round
    if isfield(whichFeatS.resample,'intensityRounding') && ...
            strcmpi(whichFeatS.resample.intensityRounding,'on')
        resampScanBounds3M = round(resampScanBounds3M);
    end

    %Resample mask
    resampMaskBounds3M = imgResample3d(single(origMask),xValsV,yValsV,...
        zValsV,xResampleV,yResampleV,zResampleV,roiInterpMethod) >= 0.5;
    
    newSlcIndV = zeros(1,length(zResampleV));
    for iSlc = 1:length(zResampleV)
        newSlcIndV(iSlc) = findnearest(zValsV, zResampleV(iSlc));
    end
    
else
    resampScanBounds3M = padScanBoundsForResamp3M;
    resampMaskBounds3M = padMaskBoundsForResamp3M;
    xResampleV = xValsV;
    yResampleV = yValsV;
    zResampleV = zValsV;
    newSlcIndV = 1:length(slcIndV);
    dx = abs(median(diff(xResampleV)));
    dy = abs(median(diff(yResampleV)));
    dz = abs(median(diff(zResampleV)));
    outputResV = [dx dy dz];
end

%Apply padding as required for convolutional filtering
if whichFeatS.padding.flag
    if isfield(whichFeatS.padding,'cropToMaskBounds')
        cropFlag = strcmpi(whichFeatS.padding.cropToMaskBounds,'yes');
    else
        cropFlag = 1; %default
    end
    if isfield(whichFeatS.padding,'method') && ...
            ~strcmpi(whichFeatS.padding.method,'none')
        filtPadMethod = whichFeatS.padding.method;
        filtPadSizeV = reshape(whichFeatS.padding.size,1,[]);
        if length(filtPadSizeV)==2
            filtPadSizeV = [filtPadSizeV,0];
        end
    else
        filtPadMethod = 'none';
        filtPadSizeV = [0 0 0];
    end

    [volToEval,maskBoundingBox3M,outLimitsV] = padScan(resampScanBounds3M,...
        resampMaskBounds3M,filtPadMethod,filtPadSizeV,cropFlag);

    %Extend resampling grid if padding original image (cropFlag=0)
    if outLimitsV(1)<1
        numPad = (1-outLimitsV(1));
        yExtendV = yResampleV(1)-(1:numPad)*outputResV(2);
        yResampleV = [yExtendV,yResampleV];
        outLimitsV(1) = outLimitsV(1)+numPad;
        outLimitsV(2) = outLimitsV(2)+numPad;
    end
    if outLimitsV(3)<1
        numPad = (1-outLimitsV(3));
        xExtendV = xResampleV(1)-(1:numPad)*outputResV(1);
        xResampleV = [xExtendV,xResampleV];
        outLimitsV(3) = outLimitsV(3)+numPad;
        outLimitsV(4) = outLimitsV(4)+numPad;
    end
    if outLimitsV(5)<1
        numPad = (1-outLimitsV(5));
        zExtendV = zResampleV(1)-(1:numPad)*outputResV(3);
        zResampleV = [zExtendV,zResampleV];
        outLimitsV(5) = outLimitsV(5)+numPad;
        outLimitsV(6) = outLimitsV(6)+numPad;
    end
    if outLimitsV(2)>length(yResampleV)
        numPad = (outLimitsV(2)-length(yResampleV));
        yExtendV = yResampleV(end)+(1:numPad)*outputResV(2);
        yResampleV = [yResampleV,yExtendV];
    end
    if outLimitsV(4)>xResampleV(end)
        numPad = (outLimitsV(4)-length(xResampleV));
        xExtendV = xResampleV(end)+(1:numPad)*outputResV(1);
        xResampleV = [xResampleV,xExtendV];
    end
    if outLimitsV(6)>zResampleV(end)
        numPad = (outLimitsV(6)-length(zResampleV));
        zExtendV = zResampleV(end)+(1:numPad)*outputResV(3);
        zResampleV = [zResampleV,zExtendV];
    end
    xResampleV = xResampleV(outLimitsV(3):outLimitsV(4));
    yResampleV = yResampleV(outLimitsV(1):outLimitsV(2));
    zResampleV = zResampleV(outLimitsV(5):outLimitsV(6));
else
%     resampSizeV = size(resampScanBounds3M);
%     volToEval = resampScanBounds3M(padSizV(1)+1:resampSizeV(1)-padSizV(1),...
%         padSizV(2)+1:resampSizeV(2)-padSizV(2),...
%         padSizV(3)+1:resampSizeV(3)-padSizV(3));
%     maskBoundingBox3M = resampMaskBounds3M(padSizV(1)+1:resampSizeV(1)-padSizV(1),...
%         padSizV(2)+1:resampSizeV(2)-padSizV(2),...
%         padSizV(3)+1:resampSizeV(3)-padSizV(3));
%    resampSizeV = size(resampScanBounds3M);
    volToEval = resampScanBounds3M;
    maskBoundingBox3M = resampMaskBounds3M;
end


%--- 4. Ignore voxels below and above cutoffs, if defined ----

minSegThreshold = [];
maxSegThreshold = [];
if isfield(paramS,'textureParamS')
    if isfield(paramS.textureParamS,'minSegThreshold')
        minSegThreshold = paramS.textureParamS.minSegThreshold;
    end
    if isfield(paramS.textureParamS,'maxSegThreshold')
        maxSegThreshold = paramS.textureParamS.maxSegThreshold;
    end
    if ~isempty(minSegThreshold)
        maskBoundingBox3M(volToEval < minSegThreshold) = 0;
    end
    if ~isempty(maxSegThreshold)
        maskBoundingBox3M(volToEval > maxSegThreshold) = 0;
    end
end
%volToEval(~maskBoundingBox3M) = NaN;
volV = volToEval(maskBoundingBox3M);
diagS.numVoxelsInterpReseg = sum(maskBoundingBox3M(:));
diagS.MeanIntensityInterpReseg = mean(volV);
diagS.MaxIntensityInterpReseg = max(volV);
diagS.MinIntensityInterpReseg = min(volV);


% Return grid and pixel-spacing
gridS.xValsV = xResampleV;
gridS.yValsV = yResampleV;
gridS.zValsV = zResampleV;
gridS.PixelSpacingV = [PixelSpacingX,PixelSpacingY,PixelSpacingZ];

% Pass scanInfo as an additional parameter for imageType = SUV
if numel(scanNum) == 1
    % Get image types with various parameters
    fieldNamC = fieldnames(paramS.imageType);
    for iImg = 1:length(fieldNamC)
        for iFilt = 1:length(paramS.imageType.(fieldNamC{iImg}))
            imageType = fieldNamC{iImg};
            if strcmpi(imageType,'SUV')
                scanInfoS = planC{indexS.scan}(scanNum).scanInfo;
                scanInfoS = scanInfoS(slcIndV); % slices for the cropped volume
                scanInfoS = scanInfoS(newSlcIndV); % resampled slices
                paramS.imageType.(fieldNamC{iImg})(iFilt).scanInfoS = scanInfoS;
            end
        end
    end
end

end