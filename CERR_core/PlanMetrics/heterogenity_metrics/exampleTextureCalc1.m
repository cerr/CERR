% exampleTextureCalc1.m
%
% Example script for texture calculation
%
% APA, 05/23/2016

global planC

%% EXAMPLE 1: Patch-wise texture
scanNum     = 1;
structNum   = 3;
descript    = 'CTV texture';
patchUnit   = 'vox'; % or 'cm'
patchSizeV  = [1 1 1];
category    = 1;
dirctn      = 1; % 2: 2d neighbors
numGrLevels = 16; % 32, 64, 256 etc..
energyFlg = 1; % or 0
entropyFlg = 1; % or 0
sumAvgFlg = 1; % or 0
homogFlg = 1; % or 0
contrastFlg = 1; % or 0
corrFlg = 1; % or 0
clustShadFlg = 1; % or 0
clustPromFlg = 1; % or 0
haralCorrFlg = 1; % or 0
flagsV = [energyFlg, entropyFlg, sumAvgFlg, corrFlg, homogFlg, ...
    contrastFlg, clustShadFlg, clustPromFlg, haralCorrFlg];
planC = createTextureMaps(scanNum,structNum,descript,...
    patchUnit,patchSizeV,category,dirctn,numGrLevels,flagsV,planC);


%% EXAMPLE 2: Texture for the entire structure
global planC
indexS = planC{end};
scanNum     = 1;
structNum   = 3;
numGrLevels = 16;
dirctn      = 1; % 2: 2d neighbors
cooccurType = 1; % 2: build separate cooccurrence for each direction

% Quantize the volume of interest
[rasterSegments, planC, isError]    = getRasterSegments(structNum,planC);
[mask3M, uniqueSlices]              = rasterToMask(rasterSegments, scanNum, planC);
scanArray3M                         = getScanArray(planC{indexS.scan}(scanNum));
SUVvals3M                           = mask3M.*double(scanArray3M(:,:,uniqueSlices));
[minr, maxr, minc, maxc, mins, maxs]= compute_boundingbox(mask3M);
maskBoundingBox3M                   = mask3M(minr:maxr,minc:maxc,mins:maxs);
volToEval                           = SUVvals3M(minr:maxr,minc:maxc,mins:maxs);
volToEval(maskBoundingBox3M==0)     = NaN;
quantizedM = imquantize_cerr(volToEval,numGrLevels);

% Buiild cooccurrence matrix
offsetsM = getOffsets(dirctn);
cooccurM = calcCooccur(quantizedM, offsetsM, numGrLevels, cooccurType);

% Reduce cooccurrence matrix to scalar features
flagS.energy = 1;
flagS.entropy = 1;
flagS.contrast = 1;
flagS.invDiffMoment = 1;
flagS.sumAvg = 1;
flagS.corr = 1;
flagS.clustShade = 1;
flagS.clustProm = 1;
flagS.haralickCorr = 1;
featureS = cooccurToScalarFeatures(cooccurM, flagS);

