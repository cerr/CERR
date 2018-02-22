function featureS = ...
    calcGlobalRadiomicsFeatures(scanNum, structNum, paramS, planC)
%
% Wrapper to extract global radiomics features
%
% APA, 6/3/2017
% MCO, 04/19/2017
% Based on APA, 04/17/2017

siz = size(scanNum);
if prod(siz) == 1
    if ~exist('planC','var')
        global planC
    end
    
    indexS = planC{end};
    
    % Get structure
    [rasterSegments, planC, isError] = getRasterSegments(structNum,planC);
    [mask3M, uniqueSlices] = rasterToMask(rasterSegments, scanNum, planC);
    scanArray3M = getScanArray(planC{indexS.scan}(scanNum));
    scanArray3M = double(scanArray3M) - ...
        planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;
    % Wavelet decomposition
    %dirString = 'LLL';
    %wavType = 'coif1';
    % scanArray3M = wavDecom3D(scanArray3M,dirString,wavType);
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
    % Voxel volume for Total Energy calculation
    VoxelVol = PixelSpacingX*PixelSpacingY*PixelSpacingZ*1000; % convert cm to mm
    
else
    volToEval = scanNum;
    maskBoundingBox3M = structNum;
    VoxelVol = planC;
end

if paramS.toQuantizeFlag == 1
    % Quantize the volume of interest
    numGrLevels = paramS.higherOrderParamS.numGrLevels;
    minIntensity = paramS.higherOrderParamS.minIntensity;
    maxIntensity = paramS.higherOrderParamS.maxIntensity;
    %minIntensity = min(volToEval(:));
    %maxIntensity = max(volToEval(:));
    %numGrLevels = ceil((maxIntensity - minIntensity)/25);
    paramS.higherOrderParamS.numGrLevels = numGrLevels;
    quantizedM = imquantize_cerr(volToEval,numGrLevels,...
        minIntensity,maxIntensity);
else
    quantizedM = volToEval;
end
%clear volToEval

quantizedM(~maskBoundingBox3M) = NaN;
numVoxels = sum(~isnan(quantizedM(:)));

whichFeatS = paramS.whichFeatS;

% Feature calculation
featureS = struct;
if whichFeatS.shape
%     [featureS.shapeS] = getShapeParams(maskBoundingBox3M, ...
%         {xValsV, yValsV, zValsV}, paramS.shapeParamS.rcsV);
    [featureS.shapeS] = getShapeParams(maskBoundingBox3M, ...
        {xValsV, yValsV, zValsV});
end

if whichFeatS.harFeat2Ddir
    numGrLevels = paramS.higherOrderParamS.numGrLevels;
    glcmFlagS = getHaralickFlags();
        
    % 2D Haralick features from separate cooccurrence matrix per direction, averaged
    dirctn      = 2;
    cooccurType = 2;
    featureS.harFeat2DdirS = get_haralick(dirctn, cooccurType, quantizedM, ...
        numGrLevels, glcmFlagS);
    
end
if whichFeatS.harFeat2Dcomb
    numGrLevels = paramS.higherOrderParamS.numGrLevels;
    glcmFlagS = getHaralickFlags();
    
    % 2D Haralick features with combined cooccurrence matrix
    dirctn      = 2;
    cooccurType = 1;
    featureS.harFeat2DcombS = get_haralick(dirctn, cooccurType, quantizedM, ...
    numGrLevels, glcmFlagS);
end
if whichFeatS.harFeat3Ddir
    numGrLevels = paramS.higherOrderParamS.numGrLevels;
    glcmFlagS = getHaralickFlags();
        
    % 3D Haralick features from separate cooccurrence matrix per direction, averaged
    dirctn      = 1;
    cooccurType = 2;
    featureS.harFeat3DdirS = get_haralick(dirctn, cooccurType, quantizedM, ...
        numGrLevels, glcmFlagS);
    
end
if whichFeatS.harFeat3Dcomb
    numGrLevels = paramS.higherOrderParamS.numGrLevels;
    glcmFlagS = getHaralickFlags();
    
    % 3D Haralick features with combined cooccurrence matrix
    dirctn      = 1;
    cooccurType = 1;
    featureS.harFeat3DcombS = get_haralick(dirctn, cooccurType, quantizedM, ...
    numGrLevels, glcmFlagS);
end

if whichFeatS.rlmFeat2Ddir
    numGrLevels = paramS.higherOrderParamS.numGrLevels;
    rlmFlagS = getRunLengthFlags();
    
    % 2D Run-Length features from separate cooccurrence matrix per direction, averaged
    dirctn  = 2;
    rlmType = 2;
    featureS.rlmFeat2DdirS = get_rlm(dirctn, rlmType, quantizedM, ...
    numGrLevels, numVoxels, rlmFlagS);    
end
if whichFeatS.rlmFeat2Dcomb
    numGrLevels = paramS.higherOrderParamS.numGrLevels;
    rlmFlagS = getRunLengthFlags();
    
    % 2D Run-Length features from combined run length matrix
    dirctn      = 2;
    rlmType     = 1;
    featureS.rlmFeat2DcombS = get_rlm(dirctn, rlmType, quantizedM, ...
    numGrLevels, numVoxels, rlmFlagS);    
end
if whichFeatS.rlmFeat3Ddir
    numGrLevels = paramS.higherOrderParamS.numGrLevels;
    rlmFlagS = getRunLengthFlags();
    
    % 2D Run-Length features from separate cooccurrence matrix per direction, averaged
    dirctn  = 1;
    rlmType = 2;
    featureS.rlmFeat3DdirS = get_rlm(dirctn, rlmType, quantizedM, ...
    numGrLevels, numVoxels, rlmFlagS);    
end
if whichFeatS.rlmFeat3Dcomb
    numGrLevels = paramS.higherOrderParamS.numGrLevels;
    rlmFlagS = getRunLengthFlags();
    
    % 2D Run-Length features from combined run length matrix
    dirctn      = 1;
    rlmType     = 1;
    featureS.rlmFeat3DcombS = get_rlm(dirctn, rlmType, quantizedM, ...
    numGrLevels, numVoxels, rlmFlagS);    
end

if whichFeatS.ngtdmFeatures2d
    numGrLevels = paramS.higherOrderParamS.numGrLevels;
    patchRadius2dV = paramS.higherOrderParamS.patchRadius2dV;            
    % 2d
    [s,p] = calcNGTDM(quantizedM, patchRadius2dV, numGrLevels);
    featureS.ngtdmFeatures2dS = ngtdmToScalarFeatures(s,p,numVoxels);
end
if whichFeatS.ngtdmFeatures3d
    numGrLevels = paramS.higherOrderParamS.numGrLevels;
    patchRadius3dV = paramS.higherOrderParamS.patchRadius3dV;
    % 3d
    [s,p] = calcNGTDM(quantizedM, patchRadius3dV, numGrLevels);
    featureS.ngtdmFeatures3dS = ngtdmToScalarFeatures(s,p,numVoxels);
end
if whichFeatS.ngldmFeatures2d
    numGrLevels = paramS.higherOrderParamS.numGrLevels;
    patchRadius2dV = paramS.higherOrderParamS.patchRadius2dV;
    imgDiffThresh = paramS.higherOrderParamS.imgDiffThresh;
    % 2d
    ngldmM = calcNGLDM(quantizedM, patchRadius2dV, ...
        numGrLevels, imgDiffThresh);
    featureS.ngldmFeatures2dS = ngldmToScalarFeatures(ngldmM,numVoxels);
    
end
if whichFeatS.ngldmFeatures3d
    numGrLevels = paramS.higherOrderParamS.numGrLevels;
    patchRadius3dV = paramS.higherOrderParamS.patchRadius3dV;
    imgDiffThresh = paramS.higherOrderParamS.imgDiffThresh;    
    % 3d
    ngldmM = calcNGLDM(quantizedM, patchRadius3dV, ...
        numGrLevels, imgDiffThresh);
    featureS.ngldmFeatures3dS = ngldmToScalarFeatures(ngldmM,numVoxels);
end
if whichFeatS.szmFeature2d
    rlmFlagS = getRunLengthFlags(); 
    % 2d
    szmType = 2; % 1: 3d, 2: 2d
    szmM = calcSZM(quantizedM, numGrLevels, szmType);
    numVoxels = sum(~isnan(quantizedM(:)));
    featureS.szmFeature2dS = rlmToScalarFeatures(szmM,numVoxels, rlmFlagS);
end
if whichFeatS.szmFeature3d
    rlmFlagS = getRunLengthFlags();
    % 3d
    szmType = 1; % 1: 3d, 2: 2d
    szmM = calcSZM(quantizedM, numGrLevels, szmType);
    numVoxels = sum(~isnan(quantizedM(:)));
    featureS.szmFeature3dS = rlmToScalarFeatures(szmM,numVoxels, rlmFlagS);
end

% if whichFeatS.highOrder
%     numGrLevels = paramS.higherOrderParamS.numGrLevels;
%     patchRadius2dV = paramS.higherOrderParamS.patchRadius2dV;    
%     patchRadius3dV = paramS.higherOrderParamS.patchRadius3dV;
%     imgDiffThresh = paramS.higherOrderParamS.imgDiffThresh;    
%     [featureS.harFeat2DdirS, featureS.harFeat3DdirS] = ...
%         runHaralick(numGrLevels, quantizedM);
%     [featureS.rlmFeat2DdirS, featureS.rlmFeat3DdirS] = ...
%         runRLM(numGrLevels, quantizedM, numVoxels);
%     [featureS.ngtdmFeatures2dS, featureS.ngtdmFeatures3dS] = ...
%         runNGTDM(numGrLevels,quantizedM, numVoxels, ...
%         patchRadius2dV, patchRadius3dV);
%     [featureS.ngldmFeatures2dS, featureS.ngldmFeatures3dS] = ...
%         runNGLDM(numGrLevels, quantizedM, numVoxels, ...
%         patchRadius2dV, patchRadius3dV, imgDiffThresh);
%     [featureS.szmFeature2dS, featureS.szmFeature3dS] = ...
%         runSizeZone(numGrLevels, quantizedM, numVoxels);
% end

if whichFeatS.firstOrder
    featureS.firstOrderS = radiomics_first_order_stats...
        (volToEval(logical(maskBoundingBox3M)), VoxelVol,...
        paramS.firstOrderParamS.offsetForEnergy);    
end
if whichFeatS.peakValley
    radiusV = paramS.peakValleyParamS.peakRadius;
    featureS.peakValleyFeatureS = getImPeakValley(maskBoundingBox3M,...
        volToEval, radiusV, 'vox');
end
if whichFeatS.ivh
    IVHBinWidth = 0.1;
    xForIxV = paramS.ivhParamS.xForIxV; % percentage volume
    xAbsForIxV = paramS.ivhParamS.xAbsForIxV; % absolute volume [cc]
    xForVxV = paramS.ivhParamS.xForVxV; % percent intensity cutoff
    xAbsForVxV = paramS.ivhParamS.xAbsForVxV; % absolute intensity cutoff [HU]
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


function glcmFlagS = getHaralickFlags()

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
end

function rlmFlagS = getRunLengthFlags()

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
end