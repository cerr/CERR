function featureS = calcRadiomicsForImgType(volOrig3M,maskBoundingBox3M,paramS,gridS)
%calcRadiomicsForImgType.m
%Derive user-defined image type and extract radiomics features.
%
%AI 3/28/19


% Voxel volume for Total Energy calculation
xValsV = gridS.xValsV;
yValsV = gridS.yValsV;
zValsV = gridS.zValsV;
PixelSpacingX = gridS.PixelSpacingV(1);
PixelSpacingY = gridS.PixelSpacingV(2);
PixelSpacingZ = gridS.PixelSpacingV(3);
VoxelVol = PixelSpacingX*PixelSpacingY*PixelSpacingZ*1000; % convert cm to mm

% Clip original image for computing derived image
minIntensityCutoff = [];
maxIntensityCutoff = [];
if isfield(paramS.textureParamS,'minIntensityCutoff')
    minIntensityCutoff = paramS.textureParamS.minIntensityCutoff;
end
if isfield(paramS.textureParamS,'maxIntensityCutoff')
    maxIntensityCutoff = paramS.textureParamS.maxIntensityCutoff;
end
if ~isempty(minIntensityCutoff)
    volOrig3M(volOrig3M < minIntensityCutoff) = minIntensityCutoff;
end
if ~isempty(maxIntensityCutoff)
    volOrig3M(volOrig3M > maxIntensityCutoff) = maxIntensityCutoff;
end
whichFeatS = paramS.whichFeatS;
featureS = struct;

imageTypeC = fieldnames(paramS.imageType);
%% Loop over image types
for k = 1:length(imageTypeC)
    
    %Generate volume based on original/derived imageType
    if strcmpi(imageTypeC{k},'original')
        minIntensityCutoff = [];
        maxIntensityCutoff = [];
        if isfield(paramS.textureParamS,'minIntensityCutoff')
            minIntensityCutoff = paramS.textureParamS.minIntensityCutoff;
        end
        if isfield(paramS.textureParamS,'maxIntensityCutoff')
            maxIntensityCutoff = paramS.textureParamS.maxIntensityCutoff;
        end        
        volToEval = volOrig3M;
        quantizeFlag = paramS.toQuantizeFlag;
    else
        outS = processImage(imageTypeC{k},volOrig3M,maskBoundingBox3M,...
            paramS.imageType.(imageTypeC{k}));
        derivedImgName = fieldnames(outS);
        volToEval = outS.(derivedImgName{1});
        quantizeFlag = true; % always quantize the derived image
        minIntensityCutoff = []; % no clipping imposed for derived images
        maxIntensityCutoff = []; % no clipping imposed for derived images
    end
    
    % Quantize the volume of interest
    if quantizeFlag        
        numGrLevels = [];
        binwidth = [];
        if isfield(paramS.textureParamS,'numGrLevels')
            numGrLevels = paramS.textureParamS.numGrLevels;
        end
        if isfield(paramS.textureParamS,'binwidth')
            binwidth = paramS.textureParamS.binwidth;
        end
        
        quantizedM = imquantize_cerr(volToEval,numGrLevels,...
            minIntensityCutoff,maxIntensityCutoff,binwidth);
        % Reassign the number of gray levels in case they were computed for the
        % passed binwidth
        numGrLevels = max(quantizedM(:));
        paramS.textureParamS.numGrLevels = numGrLevels;
        
    else
        quantizedM = volToEval;
    end
    
    quantizedM(~maskBoundingBox3M) = NaN;
    numVoxels = sum(~isnan(quantizedM(:)));
    
    
    %Feature calculation
    outFieldName = createFieldNameFromParameters(paramS,imageTypeC{k});

    % --- 1. First-order features ---
    if whichFeatS.firstOrder.flag
        featureS.(outFieldName).firstOrderS = radiomics_first_order_stats...
            (volToEval(logical(maskBoundingBox3M)), VoxelVol,...
            paramS.firstOrderParamS.offsetForEnergy,paramS.firstOrderParamS.binWidthEntropy);
    end
    
    %---2. Shape features ----
    if whichFeatS.shape.flag
        rcsV = [];
        if isfield(paramS.shapeParamS,'rcs')
            rcsV = paramS.shapeParamS.rcs.';
        end
        featureS.(outFieldName).shapeS = getShapeParams(maskBoundingBox3M, ...
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
            featureS.(outFieldName).ivhFeaturesS = getIvhParams(structNum, scanNum, IVHBinWidth,...
                xForIxV, xAbsForIxV, xForVxV, xAbsForVxV,planC);
            
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
        glcmFlagS.diffAvg = 1;
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
            featureC = lower(varargin{1});
            allFeatC = fieldnames(rlmFlagS);
            idxV = find(~ismember(allFeatC,featureC));
            for n = 1:length(idxV)
                rlmFlagS.(allFeatC{idxV(n)})  = 0;
            end
        end
        
    end

function szmFlagS = getSizeZoneFlags(varargin)
                
        szmFlagS.gln = 1;
        szmFlagS.glnNorm = 1;
        szmFlagS.glv = 1;
        szmFlagS.hglze = 1;
        szmFlagS.lglze = 1;
        szmFlagS.lae = 1;
        szmFlagS.lahgle = 1;
        szmFlagS.lalgle = 1;
        szmFlagS.szn = 1;
        szmFlagS.sznNorm = 1;
        szmFlagS.szv = 1;
        szmFlagS.zp = 1;
        szmFlagS.sae = 1;    
        szmFlagS.salgle = 1;
        szmFlagS.sahgle = 1;
        szmFlagS.ze = 1;
        
        
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