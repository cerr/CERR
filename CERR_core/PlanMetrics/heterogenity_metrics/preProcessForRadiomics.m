function [volToEval,maskBoundingBox3M,gridS] = preProcessForRadiomics(scanNum,...
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
if whichFeatS.padding.flag
    
    scanArray3M = double(scanArray3M);
    if ~isfield(whichFeatS.padding,'method')
        %Default:no padding
        padMethod = 'none';
        padSizV = [0,0,0]; 
    else
        padMethod = whichFeatS.padding.method;
        padSizV = whichFeatS.padding.size;
    end
    [volToEval,maskBoundingBox3M,outLimitsV] = padScan(scanArray3M,mask3M,padMethod,padSizV);
    
    % Crop grid and Pixelspacing (dx,dy,dz)
    xValsV = xValsV(outLimitsV(3):outLimitsV(4));
    yValsV = yValsV(outLimitsV(1):outLimitsV(2));
    zValsV = zValsV(outLimitsV(5):outLimitsV(6));
end

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
    
    % Get the new x,y,z grid
    xValsV = (xValsV(1)+perturbX):PixelSpacingX:(xValsV(end)+10000*eps+perturbX);
    yValsV = (yValsV(1)+perturbY):PixelSpacingY:(yValsV(end)+10000*eps+perturbY);
    zValsV = (zValsV(1)+perturbZ):PixelSpacingZ:(zValsV(end)+10000*eps+perturbZ);
    
    % Interpolate using sinc sampling
    numCols = length(xValsV);
    numRows = length(yValsV);
    numSlcs = length(zValsV);
    
    switch whichFeatS.resample.interpMethod
        case 'sinc'
            method = 'lanczos3'; % Lanczos-3 kernel
        case 'cubic'
            method = 'cubic'; % cubic kernel
        case 'linear'
            method = 'linear'; % 
        case 'triangle'
            method = 'triangle'; % cubic kernel
        otherwise
            error('Interpolatin method not supported');
    end
    volToEval = imresize3(volToEval,[numRows numCols numSlcs],...
        'method',method,'Antialiasing',false);
    %mask3M = imresize3(single(mask3M),[numRows numCols numSlcs],'method',method) >= 0.5;
    roiInterpMethod = 'linear';
    maskBoundingBox3M = imresize3(single(maskBoundingBox3M),[numRows numCols numSlcs],...
        'method',roiInterpMethod,'Antialiasing',false) >= 0.5;
end

%--- 4. Ignore voxels below and above cutoffs, if defined ----

minSegThreshold = [];
maxSegThreshold = [];
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

%volToEval(~maskBoundingBox3M) = NaN;

% Return grid and pixel-spacing
gridS.xValsV = xValsV;
gridS.yValsV = yValsV;
gridS.zValsV = zValsV;
gridS.PixelSpacingV = [PixelSpacingX,PixelSpacingY,PixelSpacingZ];

end