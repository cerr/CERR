function featureS = ...
    calcGlobalRadiomicsFeatures(scanNum, structNum, paramFilename, planC)
%
% Wrapper to extract global radiomics features
%
% APA, 6/3/2017
% MCO, 04/19/2017
% Based on APA, 04/17/2017
% AI, 3/22/19 Updated for compatibility with JSON input for batch extraction

%Read JSON parameter file
paramS = getRadiomicsParamTemplate(paramFilename);


siz = size(scanNum);
if prod(siz) == 1
    if ~exist('planC','var')
        global planC
    end
    
    indexS = planC{end};
    
    % Get structure mask
    [rasterSegments, planC, isError] = getRasterSegments(structNum,planC);
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
    [xValsV, yValsV, zValsV] = getUniformScanXYZVals(planC{indexS.scan}(scanNum));
    if yValsV(1) > yValsV(2)
        yValsV = fliplr(yValsV);
    end
    zValsV = zValsV(uniqueSlices);
    % Wavelet decomposition
    %dirString = 'LLL';
    %wavType = 'coif1';
    % scanArray3M = wavDecom3D(scanArray3M,dirString,wavType);
    
    %     % Sub-sample from uniqueSlices ---- uncomment for sub-sampling
    %     if length(uniqueSlices) > 1
    %         numSlcs = length(uniqueSlices);
    %         indKeepV = randsample(numSlcs,floor(numSlcs*0.75));
    %         uniqueSlices = uniqueSlices(indKeepV);
    %         mask3M = mask3M(:,:,indKeepV);
    %     end
    
    %     % Perturb segmentation
    %     pctJitter = 5;
    %     mask3M = jitterMask(mask3M,pctJitter);
    
else
    %volToEval = scanNum;
    %maskBoundingBox3M = structNum;
    %VoxelVol = planC;
    scanArray3M = scanNum;
    mask3M = structNum;
    % Assume xValsV,yValsV,zValsV increase monotonically.
    xValsV = planC{1};
    yValsV = planC{2};
    zValsV = planC{3};
end

%Get features to be extracted
whichFeatS = paramS.whichFeatS;

% Pixelspacing (dx,dy,dz)
PixelSpacingX = abs(xValsV(1) - xValsV(2));
PixelSpacingY = abs(yValsV(1) - yValsV(2));
PixelSpacingZ = abs(zValsV(1) - zValsV(2));

% Perturb scan and mask
perturbX = 0;
perturbY = 0;
perturbZ = 0;
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
    
    if whichFeatS.resample.flag && ~isempty(whichFeatS.resample.resolutionXCm)
        PixelSpacingX = whichFeatS.resample.resolutionXCm;
    end
    if whichFeatS.resample.flag && ~isempty(whichFeatS.resample.resolutionYCm)
        PixelSpacingY = whichFeatS.resample.resolutionYCm;
    end
    if whichFeatS.resample.flag && ~isempty(whichFeatS.resample.resolutionZCm)
        PixelSpacingZ = whichFeatS.resample.resolutionZCm;
    end
    
end

% Get the new x,y,z grid for isotropic voxels
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
%SUVvals3M = mask3M.*double(scanArray3M(:,:,uniqueSlices));
[minr, maxr, minc, maxc, mins, maxs] = compute_boundingbox(mask3M);
maskBoundingBox3M = mask3M(minr:maxr,minc:maxc,mins:maxs);

% Get the cropped scan
%volToEval = SUVvals3M(minr:maxr,minc:maxc,mins:maxs);
volToEval = double(scanArray3M(minr:maxr,minc:maxc,mins:maxs));

% Crop grid and Pixelspacing (dx,dy,dz)
xValsV = xValsV(minc:maxc);
PixelSpacingX = abs(xValsV(1) - xValsV(2));

yValsV = yValsV(minr:maxr);
PixelSpacingY = abs(yValsV(1) - yValsV(2));

if maxs > mins
    zValsV = zValsV(mins:maxs);
    PixelSpacingZ = abs(zValsV(1) - zValsV(2));
else
    PixelSpacingZ = abs(zValsV(1) - zValsV(1));
    zValsV = zValsV(mins:maxs);
end

% Voxel volume for Total Energy calculation
VoxelVol = PixelSpacingX*PixelSpacingY*PixelSpacingZ*1000; % convert cm to mm

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

volToEval(~maskBoundingBox3M) = NaN;


if paramS.toQuantizeFlag == 1
    % Quantize the volume of interest
    numGrLevels = [];
    binwidth = [];
    if isfield(paramS.textureParamS,'numGrLevels')
        numGrLevels = paramS.textureParamS.numGrLevels;
    end
    if isfield(paramS.textureParamS,'binwidth')
        binwidth = paramS.textureParamS.binwidth;
    end
    minIntensity = minIntensityCutoff;
    maxIntensity = maxIntensityCutoff;
    
    %minIntensity = min(volToEval(:));
    %maxIntensity = max(volToEval(:));
    %numGrLevels = ceil((maxIntensity - minIntensity)/25);
    paramS.textureParamS.numGrLevels = numGrLevels;
    quantizedM = imquantize_cerr(volToEval,numGrLevels,...
        minIntensity,maxIntensity,binwidth);
    % Reassign the number of gray levels
    numGrLevels = max(quantizedM(:));
    paramS.textureParamS.numGrLevels = numGrLevels;
    
else
    quantizedM = volToEval;
end
%clear volToEval

quantizedM(~maskBoundingBox3M) = NaN;
numVoxels = sum(~isnan(quantizedM(:)));



%% Feature calculation
featureS = struct;

% --- 1. First-order features ---
if whichFeatS.firstOrder.flag
    featureS.firstOrderS = radiomics_first_order_stats...
        (volToEval(logical(maskBoundingBox3M)), VoxelVol,...
        paramS.firstOrderParamS.offsetForEnergy,paramS.firstOrderParamS.binWidthEntropy);
end

%---2. Shape features ----
if whichFeatS.shape.flag
    rcsV = [];
    if isfield(paramS.shapeParamS,'rcs')
        rcsV = paramS.shapeParamS.rcs.';
    end
    [featureS.shapeS] = getShapeParams(maskBoundingBox3M, ...
        {xValsV, yValsV, zValsV},rcsV);
end

%---3. Higher-order (texture) features ----

%Get directionality and avg type
if any([whichFeatS.glcm.flag,whichFeatS.glrlm.flag,whichFeatS.gtdm.flag,...
        whichFeatS.gldm.flag,whichFeatS.glszm.flag])
    
    directionality = paramS.textureParamS.directionality;
    avgType = paramS.textureParamS.avgType;
    switch lower(directionality)
        case '2d'
            dirctn = 2;
        case '3d'
            dirctn = 1;
        otherwise
            error('Invalid input. Directionality must be "2D" or "3D"');
    end
    
    switch lower(avgType)
        case 'texturematrix'
            %Haralick features with combined cooccurrence matrix
            cooccurType = 1;
        case 'feature'
            %'Haralick features from separate cooccurrence matrix per direction, averaged'
            cooccurType = 2;
        otherwise
            error('Invalid input. Directionality must be "2D" or "3D"');
    end
    
    numGrLevels = paramS.textureParamS.numGrLevels;
    voxelOffset = paramS.textureParamS.voxelOffset;
    
    % a. GLCM
    if whichFeatS.glcm.flag
        
        featC = whichFeatS.glcm.featureList;
        glcmFlagS = getHaralickFlags(featC);
        featureS.glcmFeatS = get_haralick(dirctn, voxelOffset, cooccurType, quantizedM, ...
            numGrLevels, glcmFlagS);
        
    end
    
    % b. GLRLM
    if whichFeatS.glrlm.flag
        featC = whichFeatS.glrlm.featureList;
        rlmFlagS = getRunLengthFlags(featC);
        rlmType = cooccurType;
        featureS.rlmFeatS = get_rlm(dirctn, rlmType, quantizedM, ...
            numGrLevels, numVoxels, rlmFlagS);
    end
    
    %c. GTDM
    if whichFeatS.gldm.flag
        patchRadiusV = paramS.textureParamS.patchRadiusVox;
        [s,p] = calcNGTDM(quantizedM, patchRadiusV, ...
            numGrLevels);
    end
    featureS.ngtdmFeatS = ngtdmToScalarFeatures(s,p,numVoxels);
    
    
    %d. GLDM
    if whichFeatS.gldm.flag
        patchRadiusV = paramS.textureParamS.patchRadiusVox;
        imgDiffThresh = paramS.textureParamS.imgDiffThresh;
        ngldM = calcNGLDM(quantizedM, patchRadiusV,numGrLevels,imgDiffThresh);
    end
    featureS.ngldmFeatS = ngldmToScalarFeatures(ngldM,numVoxels);

    
    %e. GLSZM
    if whichFeatS.glszm.flag
        featC = whichFeatS.glrlm.featureList;
        rlmFlagS = getRunLengthFlags(featC);
        szmType = dirctn; % 1: 3d, 2: 2d
        szmM = calcSZM(quantizedM, numGrLevels, szmType);
        numVoxels = sum(~isnan(quantizedM(:)));
        featureS.szmFeatS = rlmToScalarFeatures(szmM,numVoxels, rlmFlagS);
    end
    
end

%f. Peak-valley
if whichFeatS.peakValley.flag
    radiusV = paramS.peakValleyParamS.peakRadius;
    units = paramS.peakValleyParamS.units; %'cm' or 'vox'
    featureS.peakValleyFeatureS = getImPeakValley(maskBoundingBox3M,...
        volToEval, radiusV, units);
end

%g. IVH
if whichFeatS.ivh.flag
    IVHBinWidth = paramS.ivhParamS.binwidth; %IVH binwidth
    xForIxV = paramS.ivhParamS.xForIxPct; % percentage volume
    xAbsForIxV = paramS.ivhParamS.xForIxCc; % absolute volume [cc]
    xForVxV = paramS.ivhParamS.xForVxPct; % percent intensity cutoff
    xAbsForVxV = paramS.ivhParamS.xForVxAbs; % absolute intensity cutoff [HU]
    featureS.ivhFeaturesS = getIvhParams(structNum, scanNum, IVHBinWidth,...
        xForIxV, xAbsForIxV, xForVxV, xAbsForVxV,planC);
    
end

end


% function [harFeat2DdirS, harFeat3DdirS] = ...
%     runHaralick(numGrLevels, quantizedM)
% %-------------------------------------------------------------------------------------------
% % dirctn:       1: 3d neighbors, 2: 2d neighbors
% % cooccurType:  1: combine cooccurrence matrix from all directions
% %               2: build separate cooccurrence for each direction
% % glcmFlagS = glcm_opts(1); % Initialize GLCM flags
% % Haralick features calculation flags
% % numGrLevels = 6; % Number of grey levels
%
% glcmFlagS = getHaralickFlags();
%
% % 2D Haralick features with combined cooccurrence matrix
% %dirctn      = 2;
% %cooccurType = 1;
% %[harFeat2DcombiS] = get_haralick(dirctn, cooccurType, quantizedM, numGrLevels, glcmFlagS);
%
% % 2D Haralick features from separate cooccurrence matrix per direction, averaged
% dirctn      = 2;
% cooccurType = 2;
% [harFeat2DdirS] = get_haralick(dirctn, cooccurType, quantizedM, ...
%     numGrLevels, glcmFlagS);
%
% % 3D Haralick features with combined cooccurrence matrix
% %dirctn      = 1;
% %cooccurType = 1;
% %[harFeat3DcombiS] = get_haralick(dirctn, cooccurType, quantizedM, numGrLevels, glcmFlagS);
%
% % 3D Haralick features from separate cooccurrence matrix per direction, averaged
% dirctn      = 1;
% cooccurType = 2;
% [harFeat3DdirS] = get_haralick(dirctn, cooccurType, quantizedM, ...
%     numGrLevels, glcmFlagS);
% end
%
%
% function [rlmFeat2DdirS, rlmFeat3DdirS] = runRLM(numGrLevels, ...
%     quantizedM, numVoxels)
% %-------------------------------------------------------------------------------------------
% % rlmFlagS = rlm_opts(1); % Initialize RLM flags
% % Initialize RLM flags
%
% rlmFlagS = getRunLengthFlags();
% % dirctn:       1: 3d neighbors, 2: 2d neighbors
% % rlmType:      1: combine run-length matrix from all directions
% %               2: build separate run length matrix for each direction
%
% % 2D Run Length features with combined run length matrix
% %dirctn      = 2;
% %rlmType     = 1;
% %[rlmFeat2DcombiS] = get_rlm(dirctn, rlmType, quantizedM, numGrLevels, numVoxels, rlmFlagS);
%
% % 2D Run-Length features from separate cooccurrence matrix per direction, averaged
% dirctn  = 2;
% rlmType = 2;
% [rlmFeat2DdirS] = get_rlm(dirctn, rlmType, quantizedM, ...
%     numGrLevels, numVoxels, rlmFlagS);
%
% % 3D Run Length features with combined run length matrix
% %dirctn  = 1;
% %rlmType = 1;
% %[rlmFeat3DcombiS] = get_rlm(dirctn, rlmType, quantizedM, numGrLevels, numVoxels, rlmFlagS);
%
% % 3D Run-Length features from separate cooccurrence matrix per direction,
% dirctn  = 1;
% rlmType = 2;
% [rlmFeat3DdirS] = get_rlm(dirctn, rlmType, quantizedM, ...
%     numGrLevels, numVoxels, rlmFlagS);
% end
%
%
% function [ngtdmFeatures2dS, ngtdmFeatures3dS] = runNGTDM(numGrLevels, ...
%     quantizedM, numVoxels, patchRadius2dV, patchRadius3dV)
% %-------------------------------------------------------------------------------------------
% % 2d
% [featureS,p] = calcNGTDM(quantizedM, patchRadius2dV, numGrLevels);
% ngtdmFeatures2dS = ngtdmToScalarFeatures(featureS,p,numVoxels);
%
% % 3d
% [featureS,p] = calcNGTDM(quantizedM, patchRadius3dV, numGrLevels);
% ngtdmFeatures3dS = ngtdmToScalarFeatures(featureS,p,numVoxels);
% end
%
%
% function [ngldmFeatures2dS, ngldmFeatures3dS] = runNGLDM(numGrLevels, ...
%     quantizedM, numVoxels, patchRadius2dV, patchRadius3dV, imgDiffThresh)
% %-------------------------------------------------------------------------------------------
% % 2d
% featureS = calcNGLDM(quantizedM, patchRadius2dV, ...
%     numGrLevels, imgDiffThresh);
% ngldmFeatures2dS = ngldmToScalarFeatures(featureS,numVoxels);
%
% % 3d
% featureS = calcNGLDM(quantizedM, patchRadius3dV, ...
%     numGrLevels, imgDiffThresh);
% ngldmFeatures3dS = ngldmToScalarFeatures(featureS,numVoxels);
% end
%
%
% function [shapeS] = runShape(structNum, planC, rcsV)
% %-------------------------------------------------------------------------------------------
% shapeS = getShapeParams(structNum, planC, rcsV);
% end
%
%
% function [RadiomicsFirstOrderS] = runFirstOrder(roiObj, imgObj)
% %-------------------------------------------------------------------------------------------
% RadiomicsFirstOrderS = radiomics_first_order_stats...
%     (imgObj(logical(roiObj)));
% end
%
%
% function [szmFeature2dS,szmFeature3dS] = ...
%     runSizeZone(numGrLevels, quantizedM, numVoxels)
% %-------------------------------------------------------------------------------------------
% % rlmFlagS = rlm_opts(1); % Initialize RLM flags
% % Initialize RLM flags
% rlmFlagS.sre = 1;
% rlmFlagS.lre = 1;
% rlmFlagS.gln = 1;
% rlmFlagS.glnNorm = 1;
% rlmFlagS.rln = 1;
% rlmFlagS.rlnNorm = 1;
% rlmFlagS.rp = 1;
% rlmFlagS.lglre = 1;
% rlmFlagS.hglre = 1;
% rlmFlagS.srlgle = 1;
% rlmFlagS.srhgle = 1;
% rlmFlagS.lrlgle = 1;
% rlmFlagS.lrhgle = 1;
% rlmFlagS.glv = 1;
% rlmFlagS.rlv = 1;
%
% % 2d
% szmType = 2; % 1: 3d, 2: 2d
% szmM = calcSZM(quantizedM, numGrLevels, szmType);
% numVoxels = sum(~isnan(quantizedM(:)));
% szmFeature2dS = rlmToScalarFeatures(szmM,numVoxels, rlmFlagS);
%
% % 3d
% szmType = 1; % 1: 3d, 2: 2d
% szmM = calcSZM(quantizedM, numGrLevels, szmType);
% numVoxels = sum(~isnan(quantizedM(:)));
% szmFeature3dS = rlmToScalarFeatures(szmM,numVoxels, rlmFlagS);
% end
%
% function [ivhFeaturesS] = runIVH(structNum, scanNum, ivhParamS, planC)
% %-------------------------------------------------------------------------------------------
% IVHBinWidth = 0.1;
% % xForIxV = 10:10:90; % percentage volume
% % xAbsForIxV = 10:20:200; % absolute volume [cc]
% % xForVxV = 10:10:90; % percent intensity cutoff
% % xAbsForVxV = -100:10:150; % absolute intensity cutoff [HU]
% xForIxV = ivhParamS.xForIxV;
% xAbsForIxV = ivhParamS.xAbsForIxV;
% xForVxV = ivhParamS.xForVxV;
% xAbsForVxV = ivhParamS.xAbsForVxV;
% ivhFeaturesS = getIvhParams(structNum, scanNum, IVHBinWidth,...
%     xForIxV, xAbsForIxV, xForVxV, xAbsForVxV,planC);
% end
%
% function [peakValleyFeatureS] = runPeak(roiObj, imgObj, radiusV)
% %-------------------------------------------------------------------------------------------
% % Intensity Peak (mean of voxels within x cm of a voxel)
% % radiusV = [1 1 1];
% peakValleyFeatureS = getImPeakValley(roiObj, imgObj, radiusV, 'vox');
% end


function glcmFlagS = getHaralickFlags(varargin)

%Default: all features
glcmFlagS.energy = 1;
glcmFlagS.jointEntropy = 1;
glcmFlagS.jointMax = 1;
glcmFlagS.jointAvg = 1;
glcmFlagS.jointVar = 1;
glcmFlagS.contrast = 1;
glcmFlagS.invDiffMoment = 1;
glcmFlagS.sumAvg = 1;
glcmFlagS.corr = 1;
glcmFlagS.clustShade = 1;
glcmFlagS.clustProm = 1;
glcmFlagS.haralickCorr = 1;
glcmFlagS.invDiffMomNorm = 1;
glcmFlagS.invDiff = 1;
glcmFlagS.invDiffNorm = 1;
glcmFlagS.invVar = 1;
glcmFlagS.dissimilarity = 1;
glcmFlagS.diffEntropy = 1;
glcmFlagS.diffVar = 1;
glcmFlagS.diffAvg = 1;
glcmFlagS.sumVar = 1;
glcmFlagS.sumEntropy = 1;
glcmFlagS.clustTendency = 1;
glcmFlagS.autoCorr = 1;
glcmFlagS.invDiffMomNorm = 1;
glcmFlagS.firstInfCorr = 1;
glcmFlagS.secondInfCorr = 1;

if nargin==1 && ~strcmpi(varargin{1},'all')
    featC = varargin{1};
    allFeatC = fieldnames(glcmFlagS);
    idxV = find(~ismember(allFeatC,featC));
    for s = 1:length(idxV)
        glcmFlagS.(allFeatC{idxV(s)})  = 0;
    end
end

end

function rlmFlagS = getRunLengthFlags(varargin)

rlmFlagS.sre = 1;
rlmFlagS.lre = 1;
rlmFlagS.gln = 1;
rlmFlagS.glnNorm = 1;
rlmFlagS.rln = 1;
rlmFlagS.rlnNorm = 1;
rlmFlagS.rp = 1;
rlmFlagS.lglre = 1;
rlmFlagS.hglre = 1;
rlmFlagS.srlgle = 1;
rlmFlagS.srhgle = 1;
rlmFlagS.lrlgle = 1;
rlmFlagS.lrhgle = 1;
rlmFlagS.glv = 1;
rlmFlagS.rlv = 1;
rlmFlagS.re = 1;

if nargin==1 && ~strcmpi(varargin{1},'all')
    featC = lower(varargin{1});
    allFeatC = fieldnames(rlmFlagS);
    idxV = find(~ismember(allFeatC,featC));
    for s = 1:length(idxV)
        rlmFlagS.(allFeatC{idxV(s)})  = 0;
    end
end

end