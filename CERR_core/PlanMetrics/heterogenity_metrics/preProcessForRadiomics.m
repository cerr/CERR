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
padScaleX = 1;
padScaleY = 1;
padScaleZ = 1;
if whichFeatS.resample.flag
    dx = median(diff(xValsV));
    dy = median(diff(yValsV));
    dz = median(diff(zValsV));
    padScaleX = ceil(whichFeatS.resample.resolutionXCm/dx);
    padScaleY = ceil(whichFeatS.resample.resolutionXCm/dy);
    padScaleZ = ceil(whichFeatS.resample.resolutionXCm/dz);
end
if whichFeatS.padding.flag
    if ~isfield(whichFeatS.padding,'method')
        %Default:Pad by 5 voxels (original image intensities)
        padMethod = 'expand';
        padSizV = [5,5,5];
    else
        padMethod = whichFeatS.padding.method;
        padSizV = whichFeatS.padding.size;
    end
else
    %Default:Pad by 5 voxels (original image intensities)
    padMethod = 'expand';
    padSizV = [5,5,5];
end

padSizV = padSizV.*[padScaleX,padScaleY,padScaleZ];

% Crop to ROI and pad
scanArray3M = double(scanArray3M);
[volToEval,maskBoundingBox3M,outLimitsV] = padScan(scanArray3M,mask3M,padMethod,padSizV);
xValsV = xValsV(outLimitsV(3):outLimitsV(4));
yValsV = yValsV(outLimitsV(1):outLimitsV(2));
zValsV = zValsV(outLimitsV(5):outLimitsV(6));

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
    origVolToEval = volToEval;
    origMask = maskBoundingBox3M;
    
    % Construct original image grid
    xOrigV = dx:dx:size(origVolToEval,2)*dx;
    yOrigV = dy:dy:size(origVolToEval,1)*dy;
    zOrigV = dz:dz:size(origVolToEval,3)*dz;
    
    % Get no. output rows, cols, slices
    numCols = ceil((xValsV(end) - xValsV(1) + dx)/PixelSpacingX);
    numRows = ceil((yValsV(end) - yValsV(1) + dy)/PixelSpacingY);
    numSlc = ceil((zValsV(end) - zValsV(1) + dz)/PixelSpacingZ);
    
    %Align grid centers
    xCtr = dx/2+size(origVolToEval,2)*dx/2 + perturbX;
    yCtr = dy/2+size(origVolToEval,1)*dy/2 + perturbY;
    zCtr = dz/2+size(origVolToEval,3)*dz/2 + perturbZ;
    
    % Get output grid coordinates
    xResampleV = [flip(xCtr-PixelSpacingX/2:-PixelSpacingX:0), ...
        xCtr+PixelSpacingX/2:PixelSpacingX:size(origVolToEval,2)*dx];
    yResampleV = [flip(yCtr-PixelSpacingY/2:-PixelSpacingY:0), ...
        yCtr+PixelSpacingY/2:PixelSpacingY:size(origVolToEval,1)*dy];
    zResampleV = [flip(zCtr-PixelSpacingZ/2:-PixelSpacingZ:0), ...
        zCtr+PixelSpacingZ/2:PixelSpacingZ:size(origVolToEval,3)*dz];
    
    % Get meshgrids for interpolation
    [xOrigM,yOrigM,zOrigM] = meshgrid(xOrigV,yOrigV,zOrigV);
    [xResampM,yResampM,zResampM] = meshgrid(xResampleV,yResampleV,zResampleV);
   
    % Interpolate using the method defined in settings file
    roiInterpMethod = 'linear';
    scanInterpMethod = whichFeatS.resample.interpMethod;
    extrapVal = 0;
    
    switch scanInterpMethod
        
        case {'linear','cubic','nearest'}
            volToEval = interp3(xOrigM,yOrigM,zOrigM,origVolToEval,...
                xResampM,yResampM,zResampM,scanInterpMethod,extrapVal);
            maskBoundingBox3M = interp3(xOrigM,yOrigM,zOrigM,single(origMask),...
                xResampM,yResampM,zResampM,roiInterpMethod,extrapVal) >= 0.5;
            
        case 'sinc'
            %Resize using sinc filter
            scanInterpMethod = 'lanczos3';
            volToEval = imresize3(origVolToEval,[numRows,numCols,numSlc],...
                scanInterpMethod,'Antialiasing',false);
            maskBoundingBox3M = imresize3(single(origMask),...
                [numRows,numCols,numSlc],roiInterpMethod,'Antialiasing',false);
            %Get pixel spacing
            inPixelSpacingX = (xValsV(end) - xValsV(1) + dx)/numCols;
            inPixelSpacingY = (yValsV(end) - yValsV(1) + dy)/numRows;
            inPixelSpacingZ = (zValsV(end) - zValsV(1) + dz)/numSlc;
            %Align grid centers
            inXvalsV = inPixelSpacingX:inPixelSpacingX:...
                (numCols)*inPixelSpacingX;
            inYvalsV = inPixelSpacingY:inPixelSpacingY:...
                (numRows)*inPixelSpacingY;
            inZvalsV = inPixelSpacingZ:inPixelSpacingZ:...
                (numSlc)*inPixelSpacingZ;
            inXoffset = mean(xOrigV) - mean(inXvalsV);
            inYoffset = mean(yOrigV) - mean(inYvalsV);
            inZoffset = mean(zOrigV) - mean(inZvalsV);
            inXvalsV = inXvalsV + inXoffset;
            inYvalsV = inYvalsV + inYoffset;
            inZvalsV = inZvalsV + inZoffset;
            [inGridX3M,inGridY3M,inGridZ3M] = meshgrid(inXvalsV,...
                inYvalsV,inZvalsV);
            %Adjust pixel spacing
            volToEval = interp3(inGridX3M,inGridY3M,inGridZ3M,volToEval,...
                xResampM,yResampM,zResampM,'linear');
            maskBoundingBox3M = interp3(inGridX3M,inGridY3M,inGridZ3M,...
                single(maskBoundingBox3M),xResampM,yResampM,zResampM,...
                roiInterpMethod) >= 0.5;
            
        otherwise
            error('Interpolation method %s not supported',...
                whichFeatS.resample.interpMethod);
    end
    
else
    xResampleV = xValsV;
    yResampleV = yValsV;
    zResampleV = zValsV;
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
gridS.xValsV = xResampleV;
gridS.yValsV = yResampleV;
gridS.zValsV = zResampleV;
gridS.PixelSpacingV = [PixelSpacingX,PixelSpacingY,PixelSpacingZ];

end