function featureS = calcRadiomicsForImgType(volOrig3M,maskBoundingBox3M,paramS,gridS)
%calcRadiomicsForImgType.m
%Derive user-defined image type and extract radiomics features.
%
%AI 3/28/19
%AI 5/1/19    Turned off flag for diffAvg since this is equivalent to dissimilarity. 

% Voxel volume for Total Energy calculation
xValsV = gridS.xValsV;
yValsV = gridS.yValsV;
zValsV = gridS.zValsV;
PixelSpacingX = gridS.PixelSpacingV(1);
PixelSpacingY = gridS.PixelSpacingV(2);
PixelSpacingZ = gridS.PixelSpacingV(3);
VoxelVol = PixelSpacingX*PixelSpacingY*PixelSpacingZ*1000; % convert cm to mm


whichFeatS = paramS.whichFeatS;
featureS = struct;

% Get image types with various parameters
fieldNamC = fieldnames(paramS.imageType);
imageTypeC = {};
for iImg = 1:length(fieldNamC)
    for iFilt = 1:length(paramS.imageType.(fieldNamC{iImg}))
        filtParamS = struct();
        filtParamS.imageType = fieldNamC{iImg};
        filtParamS.paramS = paramS.imageType.(fieldNamC{iImg})(iFilt);
        imageTypeC{end+1} = filtParamS;
    end
end

% ---- Calc. shape features (same across img. types) ----
tic
if whichFeatS.shape.flag
    rcsV = [];
    if isfield(paramS.shapeParamS,'rcs')
        rcsV = paramS.shapeParamS.rcs.';
    end
    featureS.shapeS = getShapeParams(maskBoundingBox3M, ...
        {xValsV, yValsV, zValsV},rcsV);
end
toc


%% Loop over image types
maskOrig3M = maskBoundingBox3M;
for k = 1:length(imageTypeC)
    
    %Generate volume based on original/derived imageType
    if strcmpi(imageTypeC{k}.imageType,'original')
        quantizeFlag = paramS.toQuantizeFlag;
        minClipIntensity = []; % no clipping imposed for derived images
        maxClipIntensity = [];
        if isfield(paramS.textureParamS,'minClipIntensity')
            minClipIntensity = paramS.textureParamS.minClipIntensity;
        end
        if isfield(paramS.textureParamS,'maxClipIntensity')
            maxClipIntensity = paramS.textureParamS.maxClipIntensity;
        end
        volToEval = volOrig3M;
        [minr, maxr, minc, maxc, mins, maxs] = compute_boundingbox(maskBoundingBox3M);
        maskBoundingBox3M = maskOrig3M(minr:maxr, minc:maxc, mins:maxs);
        volToEval = volToEval(minr:maxr, minc:maxc, mins:maxs);
    else
        %Add voxel size in mm to paramS
        voxSizV = [PixelSpacingX, PixelSpacingY, PixelSpacingZ]*10; %convert cm to mm
        imageTypeC{k}.paramS.VoxelSize_mm.val = voxSizV;
        outS = processImage(imageTypeC{k}.imageType,volOrig3M,maskOrig3M,...
            imageTypeC{k}.paramS);
        [minr, maxr, minc, maxc, mins, maxs] = compute_boundingbox(maskOrig3M);
        maskBoundingBox3M = maskOrig3M(minr:maxr, minc:maxc, mins:maxs);
        derivedImgName = fieldnames(outS);
        volToEval = outS.(derivedImgName{1});
        volToEval = volToEval(minr:maxr, minc:maxc, mins:maxs);
        quantizeFlag = true; % always quantize the derived image
        minClipIntensity = []; % no clipping imposed for derived images
        maxClipIntensity = []; % no clipping imposed for derived images
    end
    
    % Quantize the volume of interest
    if quantizeFlag        
        numGrLevels = [];
        binwidth = [];
        
        if isfield(paramS.textureParamS,'numGrLevels')
            numGrLevels = paramS.textureParamS.numGrLevels;
        end
        if isfield(imageTypeC{k}.paramS,'textureParamS') && ...
                isfield(imageTypeC{k}.paramS.textureParamS,'numGrLevels')
            numGrLevels = imageTypeC{k}.paramS.textureParamS.numGrLevels;
        end
        
        if isfield(paramS.textureParamS,'binwidth')
            binwidth = paramS.textureParamS.binwidth;
        end
        if isfield(imageTypeC{k}.paramS,'textureParamS') && ...
                isfield(imageTypeC{k}.paramS.textureParamS,'binwidth')
            numGrLevels = imageTypeC{k}.paramS.textureParamS.binwidth;
        end
        
        % Don't use intensities outside the ROI in discretization
        volToEval(~maskBoundingBox3M) = NaN;
        quantizedM = imquantize_cerr(volToEval,numGrLevels,...
            minClipIntensity,maxClipIntensity,binwidth);
        % Reassign the number of gray levels in case they were computed for the
        % passed binwidth
        numGrLevels = max(quantizedM(:));
        %paramS.textureParamS.numGrLevels = numGrLevels;
        
    else
        quantizedM = volToEval;
    end
    
    quantizedM(~maskBoundingBox3M) = NaN;
    numVoxels = sum(~isnan(quantizedM(:)));
    
    
    %Feature calculation
    outFieldName = createFieldNameFromParameters...
        (imageTypeC{k}.imageType,imageTypeC{k}.paramS);

    % --- 1. First-order features ---
    if whichFeatS.firstOrder.flag
        offsetForEnergy = paramS.firstOrderParamS.offsetForEnergy;
        binWidthEntropy = paramS.firstOrderParamS.binWidthEntropy;
        if isfield(imageTypeC{k}.paramS,'firstOrderParamS') && ...
                isfield(imageTypeC{k}.paramS.firstOrderParamS,'offsetForEnergy')
            offsetForEnergy = imageTypeC{k}.paramS.firstOrderParamS.offsetForEnergy;
        end
        if isfield(imageTypeC{k}.paramS,'binWidthEntropy') && ...
                isfield(imageTypeC{k}.paramS.firstOrderParamS,'binWidthEntropy')
            binWidthEntropy = imageTypeC{k}.paramS.firstOrderParamS.binWidthEntropy;
        end
        volV = volToEval(logical(maskBoundingBox3M));
        featureS.(outFieldName).firstOrderS = radiomics_first_order_stats...
            (volV, VoxelVol,offsetForEnergy,binWidthEntropy);
    end
    
    %---2. Higher-order (texture) features ----
    
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
        
        %numGrLevels = paramS.textureParamS.numGrLevels;
        voxelOffset = paramS.textureParamS.voxelOffset;
        
        % a. GLCM
        if whichFeatS.glcm.flag
            
            featC = whichFeatS.glcm.featureList;
            glcmFlagS = getHaralickFlags(featC);
            featureS.(outFieldName).glcmFeatS = get_haralick(dirctn, voxelOffset, cooccurType, quantizedM, ...
                numGrLevels, glcmFlagS);
            
        end
        
        % b. GLRLM
        if whichFeatS.glrlm.flag
            featC = whichFeatS.glrlm.featureList;
            rlmFlagS = getRunLengthFlags(featC);
            rlmType = cooccurType;
            featureS.(outFieldName).rlmFeatS = get_rlm(dirctn, rlmType, quantizedM, ...
                numGrLevels, numVoxels, rlmFlagS);
        end
        
        %c. GTDM
        if whichFeatS.gldm.flag
            patchRadiusV = paramS.textureParamS.patchRadiusVox;
            [s,p] = calcNGTDM(quantizedM, patchRadiusV, ...
                numGrLevels);
            featureS.(outFieldName).ngtdmFeatS = ngtdmToScalarFeatures(s,p,numVoxels);
        end
        
        
        %d. GLDM
        if whichFeatS.gldm.flag
            patchRadiusV = paramS.textureParamS.patchRadiusVox;
            imgDiffThresh = paramS.textureParamS.imgDiffThresh;
            ngldM = calcNGLDM(quantizedM, patchRadiusV,numGrLevels,imgDiffThresh);
            featureS.(outFieldName).ngldmFeatS = ngldmToScalarFeatures(ngldM,numVoxels);
        end
        
        
        %e. GLSZM
        if whichFeatS.glszm.flag
            featC = whichFeatS.glszm.featureList;
            szmFlagS = getSizeZoneFlags(featC);
            szmType = dirctn; % 1: 3d, 2: 2d
            szmM = calcSZM(quantizedM, numGrLevels, szmType);
            numVoxels = sum(~isnan(quantizedM(:)));
            featureS.(outFieldName).szmFeatS = szmToScalarFeatures(szmM,numVoxels, szmFlagS);
        end
        
        
        
        %f. Peak-valley
        if whichFeatS.peakValley.flag
            radiusV = paramS.peakValleyParamS.peakRadius;
            units = paramS.peakValleyParamS.units; %'cm' or 'vox'
            featureS.(outFieldName).peakValleyFeatureS = getImPeakValley(maskBoundingBox3M,...
                volToEval, radiusV, units);
        end
        
        %g. IVH
        if whichFeatS.ivh.flag
            IVHBinWidth = paramS.ivhParamS.binwidth; %IVH binwidth
            xForIxV = paramS.ivhParamS.xForIxPct; % percentage volume
            xAbsForIxV = paramS.ivhParamS.xForIxCc; % absolute volume [cc]
            xForVxV = paramS.ivhParamS.xForVxPct; % percent intensity cutoff
            xAbsForVxV = paramS.ivhParamS.xForVxAbs; % absolute intensity cutoff [HU]
            scanV = double(volToEval(maskBoundingBox3M));
            volV = repmat(VoxelVol,numel(scanV),1);
            featureS.(outFieldName).ivhFeaturesS = getIvhParams(scanV, volV, IVHBinWidth,...
                xForIxV, xAbsForIxV, xForVxV, xAbsForVxV);
            
        end
    end
    
end

%% -------------- Sub-functions ----------------------------
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
        glcmFlagS.diffAvg = 0;  %Equivalent to dissimilarity
        glcmFlagS.sumVar = 1;
        glcmFlagS.sumEntropy = 1;
        glcmFlagS.clustTendency = 1;
        glcmFlagS.autoCorr = 1;
        glcmFlagS.invDiffMomNorm = 1;
        glcmFlagS.firstInfCorr = 1;
        glcmFlagS.secondInfCorr = 1;
        
        if nargin==1 && ~strcmpi(varargin{1},'all')
            featureC = varargin{1};
            allFeatC = fieldnames(glcmFlagS);
            idxV = find(~ismember(allFeatC,featureC));
            for n = 1:length(idxV)
                glcmFlagS.(allFeatC{idxV(n)})  = 0;
            end
        end
        
    end

    function rlmFlagS = getRunLengthFlags(varargin)
        
        rlmFlagS.shortRunEmphasis = 1;
        rlmFlagS.longRunEmphasis = 1;
        rlmFlagS.grayLevelNonUniformity = 1;
        rlmFlagS.grayLevelNonUniformityNorm = 1;
        rlmFlagS.runLengthNonUniformity = 1;
        rlmFlagS.runLengthNonUniformityNorm = 1;
        rlmFlagS.runPercentage = 1;
        rlmFlagS.lowGrayLevelRunEmphasis = 1;
        rlmFlagS.highGrayLevelRunEmphasis = 1;
        rlmFlagS.shortRunLowGrayLevelEmphasis = 1;
        rlmFlagS.shortRunHighGrayLevelEmphasis = 1;
        rlmFlagS.longRunLowGrayLevelEmphasis = 1;
        rlmFlagS.longRunHighGrayLevelEmphasis = 1;
        rlmFlagS.grayLevelVariance = 1;
        rlmFlagS.runLengthVariance = 1;
        rlmFlagS.runEntropy = 1;
        
        if nargin==1 && ~strcmpi(varargin{1},'all')
            featureC = lower(varargin{1});
            allFeatC = fieldnames(rlmFlagS);
            idxV = find(~ismember(allFeatC,featureC));
            for n = 1:length(idxV)
                rlmFlagS.(allFeatC{idxV(n)})  = 0;
            end
        end
        
    end

function szmFlagS = getSizeZoneFlags(varargin)
                
        szmFlagS.grayLevelNonUniformity = 1;
        szmFlagS.grayLevelNonUniformityNorm = 1;
        szmFlagS.grayLevelVariance = 1;
        szmFlagS.highGrayLevelZoneEmphasis = 1;
        szmFlagS.lowGrayLevelZoneEmphasis = 1;
        szmFlagS.largeAreaEmphasis = 1;
        szmFlagS.largeAreaHighGrayLevelEmphasis = 1;
        szmFlagS.largeAreaLowGrayLevelEmphasis = 1;
        szmFlagS.sizeZoneNonUniformity = 1;
        szmFlagS.sizeZoneNonUniformityNorm = 1;
        szmFlagS.sizeZoneVariance = 1;
        szmFlagS.zonePercentage = 1;
        szmFlagS.smallAreaEmphasis = 1;    
        szmFlagS.smallAreaLowGrayLevelEmphasis = 1;
        szmFlagS.smallAreaHighGrayLevelEmphasis = 1;
        szmFlagS.zoneEntropy = 1;
        
        
        if nargin==1 && ~strcmpi(varargin{1},'all')
            featureC = lower(varargin{1});
            allFeatC = fieldnames(szmFlagS);
            idxV = find(~ismember(allFeatC,featureC));
            for n = 1:length(idxV)
                szmFlagS.(allFeatC{idxV(n)})  = 0;
            end
        end
        
    end

end