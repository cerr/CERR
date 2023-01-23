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
category    = 1; % Haralick texture
dirctn      = 1; % 1: 3d neighbors , 2: 2d neighbors
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
structNum   = 4;
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

featureS = cooccurToScalarFeatures(cooccurM, glcmFlagS);


%% Dominant orientation
global planC
indexS = planC{end};

scanNum     = 1;
structNum   = 6;
patchSizeV  = [3 3 3];

[rasterSegments, planC, isError]    = getRasterSegments(structNum,planC);
[mask3M, uniqueSlices]              = rasterToMask(rasterSegments, scanNum, planC);
scanArray3M                         = getScanArray(planC{indexS.scan}(scanNum));

SUVvals3M                           = mask3M.*double(scanArray3M(:,:,uniqueSlices));
[minr, maxr, minc, maxc, mins, maxs]= compute_boundingbox(mask3M);
maskBoundingBox3M                   = mask3M(minr:maxr,minc:maxc,mins:maxs);
volToEval                           = SUVvals3M(minr:maxr,minc:maxc,mins:maxs);
volToEval(maskBoundingBox3M==0)     = NaN;

% volToEval = scanArray3M; % for ITK comparison

position = [400 400 300 50];
waitFig = figure('name','Creating Texture Maps','numbertitle','off',...
            'MenuBar','none','ToolBar','none','position',position);
waitAx = axes('parent',waitFig,'position',[0.1 0.3 0.8 0.4],...
    'nextplot','add','XTick',[],'YTick',[],'yLim',[0 1],'xLim',[0 1]);
waitH = patch([0 0 0 0], [0 1 1 0], [0.1 0.9 0.1],...
    'parent', waitAx);

domOrient3M = calcDominantOrientation(volToEval, patchSizeV, waitH);

vol3M = zeros(size(volToEval));
vol3M(:,30:60,5) = 1;
vol3M(30:62,:,5) = 1;
dom3M = calcDominantOrientation(vol3M, patchSizeV, waitH);

close(waitFig)


%% Law's texture
global planC
indexS = planC{end};

scanNum     = 1;
structNum   = 1;
patchSizeV  = [3 3 3];

[rasterSegments, planC, isError]    = getRasterSegments(structNum,planC);
[mask3M, uniqueSlices]              = rasterToMask(rasterSegments, scanNum, planC);
scanArray3M                         = getScanArray(planC{indexS.scan}(scanNum));

SUVvals3M                           = mask3M.*double(scanArray3M(:,:,uniqueSlices));
[minr, maxr, minc, maxc, mins, maxs]= compute_boundingbox(mask3M);
maskBoundingBox3M                   = mask3M(minr:maxr,minc:maxc,mins:maxs);
volToEval                           = SUVvals3M(minr:maxr,minc:maxc,mins:maxs);
%volToEval(maskBoundingBox3M==0)     = NaN;
volToEval(maskBoundingBox3M==0)     = nanmean(volToEval(:));
meanVol = nanmean(volToEval(:));
if exist('padarray.m','file')
    paddedVolM = padarray(volToEval,[5 5 5],meanVol,'both');
else
    paddedVolM = padarray_oct(volToEval,[5 5 5],meanVol,'both');
end
lawsMasksS = getLawsMasks();

fieldNamesC = fieldnames(lawsMasksS);
numFeatures = length(fieldNamesC);
featuresM = zeros(sum(maskBoundingBox3M(:)),numFeatures);
for i = 1:numFeatures 
    disp(i)
    text3M = convn(paddedVolM,lawsMasksS.(fieldNamesC{i}),'same');
    text3M = text3M(6:end-5,6:end-5,6:end-5);
    featuresM(:,i) = text3M(maskBoundingBox3M);
end

% Haralick textures

featuresM = zeros(sum(maskBoundingBox3M(:)),0);
for patchSiz = 1:3
    
%patchSizeV  = [2 2 2];
patchSizeV  = [patchSiz patchSiz 0];

%numGrLevels = 16;
for numGrLevels = [8 16 32]
offsetsM = getOffsets(2);

[rasterSegments, planC, isError]    = getRasterSegments(structNum,planC);
[mask3M, uniqueSlices]              = rasterToMask(rasterSegments, scanNum, planC);
scanArray3M                         = getScanArray(planC{indexS.scan}(scanNum));

SUVvals3M                           = mask3M.*double(scanArray3M(:,:,uniqueSlices));
[minr, maxr, minc, maxc, mins, maxs]= compute_boundingbox(mask3M);
maskBoundingBox3M                   = mask3M(minr:maxr,minc:maxc,mins:maxs);
volToEval                           = SUVvals3M(minr:maxr,minc:maxc,mins:maxs);
volToEval(maskBoundingBox3M==0)     = NaN;

% Haralick texture
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
waitH = NaN;
[energy3M,entropy3M,sumAvg3M,corr3M,invDiffMom3M,contrast3M, ...
    clustShade3M,clustPromin3M,haralCorr3M] = textureByPatchCombineCooccur(volToEval,...
    numGrLevels,patchSizeV,offsetsM,flagsV,waitH);

featuresM(:,end+1) = energy3M(maskBoundingBox3M);
featuresM(:,end+1) = entropy3M(maskBoundingBox3M);
featuresM(:,end+1) = sumAvg3M(maskBoundingBox3M);
featuresM(:,end+1) = corr3M(maskBoundingBox3M);
featuresM(:,end+1) = invDiffMom3M(maskBoundingBox3M);
featuresM(:,end+1) = contrast3M(maskBoundingBox3M);
featuresM(:,end+1) = clustShade3M(maskBoundingBox3M);
featuresM(:,end+1) = clustPromin3M(maskBoundingBox3M);
featuresM(:,end+1) = haralCorr3M(maskBoundingBox3M);

end
end



[coeff,score,latVar] = pca(featuresM,'NumComponents',20);
figure, plot(cumsum(latVar)./sum(latVar)*100,'linewidth',2)
xlabel('Number of components','fontsize',20)
ylabel('Explained variance','fontsize',20)
set(gca,'fontsize',20)

figure, 
for i = 1:4
    comp1M = zeros(size(maskBoundingBox3M));
    comp1M(maskBoundingBox3M) = score(:,3);
    comp1M = volToEval;   
    subplot(2,2,i), imagesc(comp1M(:,:,i)), title(['slice: ',num2str(i)])    
    axis equal, colormap('gray')
    axis off
end

comp1M = NaN*ones(size(maskBoundingBox3M));
comp1M(maskBoundingBox3M) = score(:,2);
figure, hist(comp1M(:),30)
title('Component 2','fontsize',20)


%% Neighborhood Gray Tone Difference Matrix (NGTDM)
global planC
indexS = planC{end};

% L:\Ziad\HUH_from_Maria\ASTRO_AAPM\Included_after_AAPM\mat_cropped\HUH2

scanNum     = 1;
structNum   = 27;
patchRadiusV  = [1 1 1];
numGrLevels = 16;

[rasterSegments, planC, isError]    = getRasterSegments(structNum,planC);
[mask3M, uniqueSlices]              = rasterToMask(rasterSegments, scanNum, planC);
scanArray3M                         = getScanArray(planC{indexS.scan}(scanNum));

SUVvals3M                           = mask3M.*double(scanArray3M(:,:,uniqueSlices));
[minr, maxr, minc, maxc, mins, maxs]= compute_boundingbox(mask3M);
maskBoundingBox3M                   = mask3M(minr:maxr,minc:maxc,mins:maxs);
volToEval                           = SUVvals3M(minr:maxr,minc:maxc,mins:maxs);
volToEval(maskBoundingBox3M==0)     = NaN;
quantizedM = imquantize_cerr(volToEval,numGrLevels);

hWait = NaN;
[s,p] = calcNGTDM(quantizedM,patchRadiusV,numGrLevels,hWait);

if exist('padarray.m','file')
    paddedM = padarray(quantizedM,[1 1 1],0,'both');
    paddedMaskM = padarray(maskBoundingBox3M,[1 1 1],0,'both');
else
    paddedM = padarray_oct(quantizedM,[1 1 1],0,'both');
    paddedMaskM = padarray_oct(maskBoundingBox3M,[1 1 1],0,'both');
end
[rV,cV,sV] = find3d(paddedMaskM);
mask_rcs = [rV(:),cV(:),sV(:)];
[NGTDM,vox_occurances_NGD26] = compute_3D_NGTDM_full_vol(paddedM,numGrLevels,mask_rcs);


