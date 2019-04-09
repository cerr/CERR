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
    [mask3M, uniqueSlices] = rasterToMask(rasterSegments, scanNum, planC);
    
    % Get scan
    scanArray3M = getScanArray(planC{indexS.scan}(scanNum));
    scanArray3M = double(scanArray3M) - ...
        planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;
    
    scanSiz = size(scanArray3M);
    
    % Pad scanArray and mask3M to interpolate
    minSlc = min(uniqueSlices);
    maxSlc = max(uniqueSlices);
    if minSlc > 1
        mask3M = padarray(mask3M,[0 0 1],'pre');
        uniqueSlices = [minSlc-1; uniqueSlices];
    end
    if maxSlc < scanSiz(3)
        mask3M = padarray(mask3M,[0 0 1],'post');
        uniqueSlices = [uniqueSlices; maxSlc+1];
    end
    
    scanArray3M = scanArray3M(:,:,uniqueSlices);
    
    % Get x,y,z grid for reslicing and calculating the shape features
    [xValsV, yValsV, zValsV] = getScanXYZVals(planC{indexS.scan}(scanNum));
    if yValsV(1) > yValsV(2)
        yValsV = fliplr(yValsV);
    end
    zValsV = zValsV(uniqueSlices);
   
else
   
    scanArray3M = scanNum;
    mask3M = structNum;
    
    % Assume xValsV,yValsV,zValsV increase monotonically.
    xValsV = planC{1};
    yValsV = planC{2};
    zValsV = planC{3};
    
end

% Pixelspacing (dx,dy,dz)
PixelSpacingX = abs(xValsV(1) - xValsV(2));
PixelSpacingY = abs(yValsV(1) - yValsV(2));
PixelSpacingZ = abs(zValsV(1) - zValsV(2));


%Get pre-processing parameters
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

%--- 2. Resampling ---

% Pixelspacing (dx,dy,dz) after resampling 
if whichFeatS.resample.flag && ~isempty(whichFeatS.resample.resolutionXCm)
    PixelSpacingX = whichFeatS.resample.resolutionXCm;
end
if whichFeatS.resample.flag && ~isempty(whichFeatS.resample.resolutionYCm)
    PixelSpacingY = whichFeatS.resample.resolutionYCm;
end
if whichFeatS.resample.flag && ~isempty(whichFeatS.resample.resolutionZCm)
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
%Get resampling method
if whichFeatS.resample.flag
    switch whichFeatS.resample.interpMethod
        case 'sinc'
            method = 'lanczos3';
        otherwise
            error('Interpolatin method not supported');
    end
    scanArray3M = imresize3(scanArray3M,[numRows numCols numSlcs],'method',method);
    mask3M = imresize3(single(mask3M),[numRows numCols numSlcs],'method',method) > 0.5;
end


% Crop scan around mask
margin = 10;
origSiz = size(mask3M);
[minr, maxr, minc, maxc, mins, maxs] = compute_boundingbox(mask3M);
minr = max(1,minr-margin);
maxr = min(origSiz(1),maxr+margin);
minc = max(1,minc-margin);
maxc = min(origSiz(2),maxc+margin);
mins = max(1,mins-margin);
maxs = min(origSiz(3),maxs+margin);
maskBoundingBox3M = mask3M(minr:maxr,minc:maxc,mins:maxs);

% Get the cropped scan
volToEval = double(scanArray3M(minr:maxr,minc:maxc,mins:maxs));

% Crop grid and Pixelspacing (dx,dy,dz)
xValsV = xValsV(minc:maxc);
yValsV = yValsV(minr:maxr);
zValsV = zValsV(mins:maxs);

% Ignore voxels below and above cutoffs, if defined
minIntensityCutoff = [];
maxIntensityCutoff = [];
if isfield(paramS.textureParamS,'minIntensityCutoff')
    minIntensityCutoff = paramS.textureParamS.minIntensityCutoff;
end
if isfield(paramS.textureParamS,'maxIntensityCutoff')
    maxIntensityCutoff = paramS.textureParamS.maxIntensityCutoff;
end
if ~isempty(minIntensityCutoff)
    maskBoundingBox3M(volToEval < minIntensityCutoff) = 0;
end
if ~isempty(maxIntensityCutoff)
    maskBoundingBox3M(volToEval > maxIntensityCutoff) = 0;
end

%volToEval(~maskBoundingBox3M) = NaN;

% Return grid and pixel-spacing
gridS.xValsV = xValsV;
gridS.yValsV = yValsV;
gridS.zValsV = zValsV;
gridS.PixelSpacingV = [PixelSpacingX,PixelSpacingY,PixelSpacingZ];

end