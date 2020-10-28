function [volToEval,maskBoundingBox3M,gridS,paramS] = preProcessForRadiomics(scanNum,...
    structNum, paramS, planC)
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
    
    % Get structure mask
    [rasterSegments] = getRasterSegments(structNum,planC);
    [maskUniq3M, uniqueSlices] = rasterToMask(rasterSegments, scanNum, planC);
    
    % Get scan
    scanArray3M = getScanArray(planC{indexS.scan}(scanNum));
    scanArray3M = double(scanArray3M) - ...
        planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;
    
    scanSiz = size(scanArray3M);
    
    mask3M = false(scanSiz);
    
    mask3M(:,:,uniqueSlices) = maskUniq3M;
    
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

%% Apply global settings
whichFeatS = paramS.whichFeatS;

perturbX = 0;
perturbY = 0;
perturbZ = 0;

%--- 1. Perturbation ---
if whichFeatS.perturbation.flag
    
    [scanArray3M,mask3M] = perturbImageAndSeg(scanArray3M,mask3M,planC,...
        scanNum,whichFeatS.perturbation.sequence,whichFeatS.perturbation.angle2DStdDeg,...
        whichFeatS.perturbation.volScaleStdFraction,whichFeatS.perturbation.superPixVol);
    
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
if whichFeatS.padding.flag
    if ~isfield(whichFeatS.padding,'method')
        %Default:Pad by 5 voxels (original image intensities)
        padMethod = 'expand';
        padSizV = [5,5,5];
    else
        padMethod = whichFeatS.padding.method;
        padSizV = whichFeatS.padding.size;
        padSizV = reshape(padSizV,1,[]);
    end
else
    %Default:Pad by 5 voxels (original image intensities)
    padMethod = 'expand';
    padSizV = [5,5,5];
end

padSizV = padSizV.*[padScaleX,padScaleY,padScaleZ];
whichFeatS.padding.size = padSizV;

% Crop to ROI and pad
scanArray3M = double(scanArray3M);
[volToEval,maskBoundingBox3M,outLimitsV] = padScan(scanArray3M,mask3M,padMethod,padSizV);
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
    origVolToEval = volToEval;
    origMask = maskBoundingBox3M;
    outputResV = [PixelSpacingX,PixelSpacingY,PixelSpacingZ];
    
    %Get resampling grid 
    [xResampleV,yResampleV,zResampleV] = ...
        getResampledGrid(outputResV,xValsV,yValsV,zValsV,...
        gridResampleMethod,[perturbX,perturbY,perturbZ]);
    %Resample scan
    volToEval = imgResample3d(origVolToEval,xValsV,yValsV,zValsV,...
        xResampleV,yResampleV,zResampleV,scanInterpMethod);
    %Resample mask
    maskBoundingBox3M = imgResample3d(single(origMask),xValsV,yValsV,zValsV,...
        xResampleV,yResampleV,zResampleV,roiInterpMethod) >= 0.5;
    
    newSlcIndV = zeros(1,length(zResampleV));
    for iSlc = 1:length(zResampleV)
        newSlcIndV(iSlc) = findnearest(zValsV, zResampleV(iSlc));
    end
    
else
    xResampleV = xValsV;
    yResampleV = yValsV;
    zResampleV = zValsV;
    newSlcIndV = slcIndV;
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
                scanInfoS = scanInfoS(slcIndV);
                scanInfoS = scanInfoS(newSlcIndV);
                paramS.imageType.(fieldNamC{iImg})(iFilt).scanInfoS = scanInfoS;
            end
        end
    end
end

end