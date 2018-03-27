% testRadiomicsFeaturesWithPyRadiomics.m
%
% Script to compare CERR and pyRadiomics features
%
% APA, 2/22/2018

global planC
indexS = planC{end};

% Wavelet decomposition flag
wavDecompFlg = 1; % 0: original image, 1: wavelet pre-processing

% Specify discretization
fixedMinMaxGrLevFlag = 0; % 1: to input fixed min/max/grLevels, 0: min/max 
                          % calculated for the structure and bin width of binWidth.
binWidth = 25;
structNum = 1;
scanNum = 1;
pyradScanType = 'original';

paramS.firstOrderParamS.offsetForEnergy = planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;
paramS.firstOrderParamS.binWidth = binWidth;

% Get structure
[rasterSegments, planC, isError] = getRasterSegments(structNum,planC);
[mask3M, uniqueSlices] = rasterToMask(rasterSegments, scanNum, planC);
scanArray3M = getScanArray(planC{indexS.scan}(scanNum));
scanArray3M = double(scanArray3M) - ...
    planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;
% Wavelet decomposition
if wavDecompFlg == 1
    dirString = 'HHL';
    wavType = 'coif1';
    scanArray3M = flip(scanArray3M,3);
    if mod(size(scanArray3M,3),2) > 0
        scanArray3M(:,:,end+1) = 0*scanArray3M(:,:,1);
    end
    scanArray3M = wavDecom3D(double(scanArray3M),dirString,wavType);
    if mod(size(scanArray3M,3),2) > 0
        scanArray3M = scanArray3M(:,:,1:end-1);
    end
    scanArray3M = flip(scanArray3M,3);
end

SUVvals3M = mask3M.*double(scanArray3M(:,:,uniqueSlices));
[minr, maxr, minc, maxc, mins, maxs] = compute_boundingbox(mask3M);
maskBoundingBox3M = mask3M(minr:maxr,minc:maxc,mins:maxs);

% Assign NaN to image outside mask
volToEval = SUVvals3M(minr:maxr,minc:maxc,mins:maxs);
volToEval(~maskBoundingBox3M) = NaN;

% Get x,y,z grid for the shape features (flip y to make it monotically
% increasing)
[xValsV, yValsV, zValsV] = getUniformScanXYZVals(planC{indexS.scan}(scanNum));
yValsV = fliplr(yValsV);
xValsV = xValsV(minc:maxc);
yValsV = yValsV(minr:maxr);
zValsV = zValsV(mins:maxs);
PixelSpacingX = abs(xValsV(2)-xValsV(1));
PixelSpacingY = abs(yValsV(2)-yValsV(1));
PixelSpacingZ = abs(zValsV(2)-zValsV(1));
VoxelVol = PixelSpacingX*PixelSpacingY*PixelSpacingZ*1000; % convert cm to mm

if fixedMinMaxGrLevFlag
    numGrLevels = paramS.higherOrderParamS.numGrLevels;
    minIntensity = paramS.higherOrderParamS.minIntensity;
    maxIntensity = paramS.higherOrderParamS.maxIntensity;
    % Quantize using the number of bins
    quantizedM = imquantize_cerr(volToEval,numGrLevels,...
        minIntensity,maxIntensity);

else % Quantize using the binwidth
    minIntensity = [];
    maxIntensity = [];
    numGrLevels = [];        
    quantizedM = imquantize_cerr(volToEval,numGrLevels,...
        minIntensity,maxIntensity,binwidth);    
    numGrLevels = max(quantizedM(:));
    paramS.higherOrderParamS.numGrLevels = numGrLevels;
end

paramS.higherOrderParamS.numGrLevels = numGrLevels;
paramS.higherOrderParamS.patchRadius3dV = [1 1 1];
paramS.higherOrderParamS.imgDiffThresh = 0; 

% Number of voxels (used in run percentage calculation)
numVoxels = sum(~isnan(quantizedM(:)));


%% First order features
featureS.firstOrderS = radiomics_first_order_stats...
    (volToEval(logical(maskBoundingBox3M)), VoxelVol, ...
    paramS.firstOrderParamS.offsetForEnergy, paramS.firstOrderParamS.binWidth);
firstOrderS = featureS.firstOrderS;
cerrFirstOrderV = [firstOrderS.energy, firstOrderS.totalEnergy, firstOrderS.interQuartileRange, ...
    firstOrderS.kurtosis+3, firstOrderS.max, firstOrderS.mean, firstOrderS.meanAbsDev, ...
    firstOrderS.median, firstOrderS.medianAbsDev, firstOrderS.min, ...
    firstOrderS.P10, firstOrderS.P90, firstOrderS.interQuartileRange, ...
    firstOrderS.robustMeanAbsDev, firstOrderS.rms, firstOrderS.skewness, ...
    firstOrderS.std, firstOrderS.var, firstOrderS.entropy];
pyradFirstorderNamC = {'Energy', 'TotalEnergy','InterquartileRange','Kurtosis',...
    'Maximum', 'Mean','MeanAbsoluteDeviation','Median','medianAbsDev',...
    'Minimum','10Percentile','90Percentile','InterquartileRange',...
    'RobustMeanAbsoluteDeviation','RootMeanSquared','Skewness',...
    'StandardDeviation','Variance','Entropy'};
pyradFirstorderNamC = strcat([pyradScanType,'_firstorder_'],pyradFirstorderNamC);
pyRadFirstOrderV = [];
for i = 1:length(pyradFirstorderNamC)
    if isfield(teststruct,pyradFirstorderNamC{i})
        pyRadFirstOrderV(i) = teststruct.(pyradFirstorderNamC{i});
    else
        pyRadFirstOrderV(i) = NaN;
    end
end

diffFirstOrderV = (cerrFirstOrderV - pyRadFirstOrderV) ./ cerrFirstOrderV * 100



%% Shape features
featureS.shapeS = getShapeParams(maskBoundingBox3M, ...
        {xValsV, yValsV, zValsV});
shapeS = featureS.shapeS;
cerrShapeV = [shapeS.majorAxis, shapeS.minorAxis, shapeS.leastAxis, ...
    shapeS.flatness, shapeS.elongation, shapeS.max3dDiameter, shapeS.max2dDiameterAxialPlane,...
    shapeS.max2dDiameterSagittalPlane', shapeS.max2dDiameterCoronalPlane, ...
    shapeS.Compactness1, shapeS.Compactness2, shapeS.spherDisprop, ...
    shapeS.sphericity, shapeS.surfToVolRatio/10,...
    shapeS.surfArea*100, shapeS.volume*1000];
pyradShapeNamC = {'MajorAxis', 'MinorAxis', 'LeastAxis', 'Flatness',  'Elongation', ...
    'Maximum3DDiameter', 'Maximum2DDiameterSlice', 'Maximum2DDiameterRow', ...
    'Maximum2DDiameterColumn', 'Compactness1','Compactness2','spherDisprop','Sphericity', ...
    'SurfaceVolumeRatio','SurfaceArea','Volume'};
pyradShapeNamC = strcat([pyradScanType,'_shape_'],pyradShapeNamC);
pyRadShapeV = [];
for i = 1:length(pyradShapeNamC)
    if isfield(teststruct,pyradShapeNamC{i})
        pyRadShapeV(i) = teststruct.(pyradShapeNamC{i});
    else
        pyRadShapeV(i) = NaN;
    end
end
shapeDiffV = (cerrShapeV - pyRadShapeV) ./ cerrShapeV * 100

%% GLCM features

% Define flags
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

dirctn      = 1;
cooccurType = 2;
featureS.harFeat3DdirS = get_haralick(dirctn, cooccurType, quantizedM, ...
numGrLevels, glcmFlagS);

% harlCombS = featureS.harFeat3DcombS.CombS;
harlCombS = featureS.harFeat3DdirS.AvgS;
cerrGlcmV = [harlCombS.autoCorr, harlCombS.jointAvg, harlCombS.clustPromin, harlCombS.clustShade, harlCombS.clustTendency, ...
harlCombS.contrast, harlCombS.corr, harlCombS.diffAvg, harlCombS.diffEntropy, harlCombS.diffVar, harlCombS.dissimilarity, ...
harlCombS.energy, harlCombS.jointEntropy, harlCombS.invDiff, harlCombS.invDiffMom, harlCombS.firstInfCorr, ...
harlCombS.secondInfCorr, harlCombS.invDiffMomNorm, harlCombS.invDiffNorm, harlCombS.invVar, ...
harlCombS.sumAvg, harlCombS.sumEntropy, harlCombS.sumVar];

pyradGlcmNamC = {'Autocorrelation', 'JointAverage', 'ClusterProminence', 'ClusterShade',  'ClusterTendency', ...
    'Contrast', 'Correlation', 'DifferenceAverage', 'DifferenceEntropy', 'DifferenceVariance', 'Dissimilarity', ...
    'JointEnergy', 'JointEntropy','Id','Idm', 'Imc1' , ...
    'Imc2', 'Idmn','Idn','InverseVariance', 'sumAverage', 'SumEntropy', 'sumVariance'};

pyradGlcmNamC = strcat([pyradScanType,'_glcm_'],pyradGlcmNamC);
pyRadGlcmV = [];
for i = 1:length(pyradGlcmNamC)
    if isfield(teststruct,pyradGlcmNamC{i})
        pyRadGlcmV(i) = teststruct.(pyradGlcmNamC{i});
    else
        pyRadGlcmV(i) = NaN;
    end
end

glcmDiffV = (cerrGlcmV - pyRadGlcmV) ./ cerrGlcmV * 100


%% RLM features

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

numGrLevels = paramS.higherOrderParamS.numGrLevels;

% 3D Run-Length features from combined run length matrix
dirctn      = 1;
rlmType     = 2;
featureS.rlmFeat3DdirS = get_rlm(dirctn, rlmType, quantizedM, ...
    numGrLevels, numVoxels, rlmFlagS);

rlmCombS = featureS.rlmFeat3DdirS.AvgS;
cerrRlmV = [rlmCombS.gln, rlmCombS.glnNorm, rlmCombS.glv, rlmCombS.hglre, rlmCombS.lglre, rlmCombS.lre, rlmCombS.lrhgle, ...
    rlmCombS.lrlgle, rlmCombS.rln, rlmCombS.rlnNorm, rlmCombS.rlv, rlmCombS.rp, ...
    rlmCombS.sre, rlmCombS.srhgle, rlmCombS.srlgle, rlmCombS.re];

pyradRlmNamC = {'GrayLevelNonUniformity', 'GrayLevelNonUniformityNormalized',...
    'GrayLevelVariance', 'HighGrayLevelRunEmphasis',  'LowGrayLevelRunEmphasis', ...
    'LongRunEmphasis', 'LongRunHighGrayLevelEmphasis', 'LongRunLowGrayLevelEmphasis',...
    'RunLengthNonUniformity', 'RunLengthNonUniformityNormalized', 'RunVariance', ...
    'RunPercentage', 'ShortRunEmphasis','ShortRunHighGrayLevelEmphasis', ...
    'ShortRunLowGrayLevelEmphasis','RunEntropy'};

pyradRlmNamC = strcat([pyradScanType,'_glrlm_'],pyradRlmNamC);
pyRadRlmV = [];
for i = 1:length(pyradRlmNamC)
    if isfield(teststruct,pyradRlmNamC{i})
        pyRadRlmV(i) = teststruct.(pyradRlmNamC{i});
    else
        pyRadRlmV(i) = NaN;
    end
end

rlmDiffV = (cerrRlmV - pyRadRlmV) ./ cerrRlmV * 100



%% Size Zone features in 3d

flagS.sae = 1;
flagS.lae = 1;
flagS.gln = 1;
flagS.glv = 1;
flagS.szv = 1;
flagS.glnNorm = 1;
flagS.szn = 1;
flagS.sznNorm = 1;
flagS.zp = 1;
flagS.lglze = 1;
flagS.hglze = 1;
flagS.salgle = 1;
flagS.sahgle = 1;
flagS.lalgle = 1;
flagS.larhgle = 1;
flagS.ze = 1;

szmType = 1; % 1: 3d, 2: 2d
szmM = calcSZM(quantizedM, numGrLevels, szmType);
numVoxels = sum(~isnan(quantizedM(:)));
featureS.szmFeature3dS = szmToScalarFeatures(szmM,numVoxels, szmFlagS);
szmS = featureS.szmFeature3dS;
% cerrSzmV = [szmS.gln, szmS.glnNorm, szmS.glv, szmS.hglre, szmS.lglre, szmS.lre, szmS.lrhgle, ...
%     szmS.lrlgle, szmS.rln, szmS.rlnNorm, szmS.rlv, szmS.rp, ...
%     szmS.sre, szmS.srhgle, szmS.srlgle];
cerrSzmV = [szmS.gln, szmS.glnNorm, szmS.glv, szmS.hglze, szmS.lglze, szmS.lae, szmS.lahgle, ...
    szmS.lalgle, szmS.szn, szmS.sznNorm, szmS.szv, szmS.zp, ...
    szmS.sae, szmS.sahgle, szmS.salgle, szmS.ze];

pyradSzmNamC = {'GrayLevelNonUniformity', 'GrayLevelNonUniformityNormalized',...
    'GrayLevelVariance', 'HighGrayLevelZoneEmphasis',  'LowGrayLevelZoneEmphasis', ...
    'LargeAreaEmphasis', 'LargeAreaHighGrayLevelEmphasis', 'LargeAreaLowGrayLevelEmphasis',...
    'SizeZoneNonUniformity', 'SizeZoneNonUniformityNormalized', 'ZoneVariance', ...
    'ZonePercentage', 'SmallAreaEmphasis','SmallAreaHighGrayLevelEmphasis', ...
    'SmallAreaLowGrayLevelEmphasis','ZoneEntropy'};

pyradSzmNamC = strcat([pyradScanType,'_glszm_'],pyradSzmNamC);
pyRadSzmV = [];
for i = 1:length(pyradSzmNamC)
    if isfield(teststruct,pyradSzmNamC{i})
        pyRadSzmV(i) = teststruct.(pyradSzmNamC{i});
    else
        pyRadSzmV(i) = NaN;
    end
end
szmDiffV = (cerrSzmV - pyRadSzmV) ./ cerrSzmV * 100

%% NGLDM features

patchRadius3dV = paramS.higherOrderParamS.patchRadius3dV;
imgDiffThresh = paramS.higherOrderParamS.imgDiffThresh;
% 3d
ngldmM = calcNGLDM(quantizedM, patchRadius3dV, ...
    numGrLevels, imgDiffThresh);
featureS.ngldmFeatures3dS = ngldmToScalarFeatures(ngldmM,numVoxels);

ngldmS = featureS.ngldmFeatures3dS;
cerrNgldmV = [ngldmS.lde, ngldmS.hde, ngldmS.lgce, ngldmS.hgce, ...
    ngldmS.ldlge, ngldmS.ldhge, ngldmS.hdlge, ngldmS.hdhge, ...
    ngldmS.gln, ngldmS.glnNorm, ngldmS.dcn, ngldmS.dcnNorm,...
    ngldmS.dcp, ngldmS.glv, ngldmS.dcv, ngldmS.entropy, ngldmS.energy];

pyradNgldmNamC = {'SmallDependenceEmphasis', 'LargeDependenceEmphasis',...
    'LowGrayLevelCountEmphasis', 'HighGrayLevelCountEmphasis',  'SmallDependenceLowGrayLevelEmphasis', ...
    'SmallDependenceHighGrayLevelEmphasis', 'LargeDependenceLowGrayLevelEmphasis', ...
    'LargeDependenceHighGrayLevelEmphasis', 'GrayLevelNonUniformity', 'GrayLevelNonUniformityNorm', ...
    'DependenceNonUniformity', 'DependenceNonUniformityNormalized', ...
    'DependencePercentage', 'GrayLevelVariance', 'DependenceVariance', ...
    'DependenceEntropy', 'DependenceEnergy'};

pyradNgldmNamC = strcat([pyradScanType,'_gldm_'],pyradNgldmNamC);
pyRadNgldmV = [];
for i = 1:length(pyradNgldmNamC)
    if isfield(teststruct,pyradNgldmNamC{i})
        pyRadNgldmV(i) = teststruct.(pyradNgldmNamC{i});
    else
        pyRadNgldmV(i) = NaN;
    end
end

ngldmDiffV = (cerrNgldmV - pyRadNgldmV) ./ cerrNgldmV * 100



%% NGTDM features
numGrLevels = paramS.higherOrderParamS.numGrLevels;
patchRadius3dV = paramS.higherOrderParamS.patchRadius3dV;
% 3d
[s,p] = calcNGTDM(quantizedM, patchRadius3dV, numGrLevels);
featureS.ngtdmFeatures3dS = ngtdmToScalarFeatures(s,p,numVoxels);

ngtdmS = featureS.ngtdmFeatures3dS;
cerrNgtdmV = [ngtdmS.busyness ngtdmS.coarseness ngtdmS.complexity ngtdmS.contrast ngtdmS.strength];



    