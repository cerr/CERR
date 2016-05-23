function planC = createTextureMaps(scanNum,structNum,descript,...
    patchUnit,patchSizeV,category,dirctn,numGrLevels,flagsV,planC)
%
% function planC = createTextureMaps(scanNum,structNum,descript,...
%    patchUnit,patchSizeV,category,dirctn,numGrLevels,flagsV,planC)
%
% % EXAMPLE:
% scanNum     = 1;
% structNum   = 3;
% descript    = 'CTV texture';
% patchUnit   = 'vox'; % or 'cm'
% patchSizeV  = [1 1 1];
% category    = 1;
% dirctn      = 1; % 2: 2d neighbors
% numGrLevels = 16; % 32, 64, 256 etc..
% energyFlg = 1; % or 0
% entropyFlg = 1; % or 0
% sumAvgFlg = 1; % or 0
% homogFlg = 1; % or 0
% contrastFlg = 1; % or 0
% corrFlg = 1; % or 0
% clustShadFlg = 1; % or 0
% clustPromFlg = 1; % or 0
% haralCorrFlg = 1; % or 0
% flagsV = [energyFlg, entropyFlg, sumAvgFlg, corrFlg, homogFlg, ...
%     contrastFlg, clustShadFlg, clustPromFlg, haralCorrFlg];
% planC = createTextureMaps(scanNum,structNum,descript,...
%     patchUnit,patchSizeV,category,dirctn,numGrLevels,flagsV,planC)
%
% APA, 05/02/2016

if ~exist('planC','var')
    global planC
end

indexS = planC{end};

if strcmpi(patchUnit,'cm')
    patchUnit = 'cm';
    [xVals, yVals, zVals] = getUniformScanXYZVals(planC{indexS.scan}(scanNum));
    deltaX = abs(xVals(1)-xVals(2));
    deltaY = abs(yVals(1)-yVals(2));
    deltaZ = abs(zVals(1)-zVals(2));
    slcWindow = floor(patchSizeV(3)/deltaZ);
    rowWindow = floor(patchSizeV(1)/deltaY);
    colWindow = floor(patchSizeV(2)/deltaX);
    patchSizeV = [rowWindow, colWindow, slcWindow];
else
    % no need to convert
end

offsetsM = getOffsets(dirctn);

% Create new Texture
numTextures = length(planC{indexS.texture});
currentTexture = numTextures + 1;
initTextureS = initializeCERR('texture');
initTextureS(1).textureUID = createUID('texture');
planC{indexS.texture} = dissimilarInsert(planC{indexS.texture},initTextureS);
assocScanUID = planC{indexS.scan}(scanNum).scanUID;
planC{indexS.texture}(currentTexture).assocScanUID = assocScanUID;
assocStrUID = planC{indexS.structures}(structNum).strUID;
planC{indexS.texture}(currentTexture).assocStructUID = assocStrUID;
planC{indexS.texture}(currentTexture).category = category;



[rasterSegments, planC, isError]    = getRasterSegments(structNum,planC);
[mask3M, uniqueSlices]              = rasterToMask(rasterSegments, scanNum, planC);
scanArray3M                         = getScanArray(planC{indexS.scan}(scanNum));

SUVvals3M                           = mask3M.*double(scanArray3M(:,:,uniqueSlices));
[minr, maxr, minc, maxc, mins, maxs]= compute_boundingbox(mask3M);
maskBoundingBox3M                   = mask3M(minr:maxr,minc:maxc,mins:maxs);
volToEval                           = SUVvals3M(minr:maxr,minc:maxc,mins:maxs);
volToEval(maskBoundingBox3M==0)     = NaN;
volToEval                           = volToEval / max(volToEval(:));
%volToEval                           = sqrt(volToEval);

% volToEval = scanArray3M; % for ITK comparison

position = [400 400 300 50];
waitFig = figure('name','Creating Texture Maps','numbertitle','off',...
            'MenuBar','none','ToolBar','none','position',position);
waitAx = axes('parent',waitFig,'position',[0.1 0.3 0.8 0.4],...
    'nextplot','add','XTick',[],'YTick',[],'yLim',[0 1],'xLim',[0 1]);
waitH = patch([0 0 0 0], [0 1 1 0], [0.1 0.9 0.1],...
    'parent', waitAx);

[energy3M,entropy3M,sumAvg3M,corr3M,invDiffMom3M,contrast3M, ...
    clustShade3M,clustPromin3M,haralCorr3M] = textureByPatchCombineCooccur(volToEval,...
    numGrLevels,patchSizeV,offsetsM,flagsV,waitH);

close(waitFig)

energyFlg = flagsV(1);
entropyFlg = flagsV(2);
sumAvgFlg = flagsV(3);
corrFlg = flagsV(4);
homogFlg = flagsV(5);
contrastFlg = flagsV(6);
clustShadFlg = flagsV(7);
clustPromFlg = flagsV(8);
haralCorrFlg = flagsV(9);

planC{indexS.texture}(currentTexture).paramS.direction = dirctn;
planC{indexS.texture}(currentTexture).paramS.numGrLevels = numGrLevels;
planC{indexS.texture}(currentTexture).paramS.energyFlag = energyFlg;
planC{indexS.texture}(currentTexture).paramS.entropyFlag = entropyFlg;
planC{indexS.texture}(currentTexture).paramS.sumAvgFlag = sumAvgFlg;
planC{indexS.texture}(currentTexture).paramS.corrFlag = corrFlg;
planC{indexS.texture}(currentTexture).paramS.homogFlag = homogFlg;
planC{indexS.texture}(currentTexture).paramS.contrastFlag = contrastFlg;
planC{indexS.texture}(currentTexture).paramS.clusterShadeFlag = clustShadFlg;
planC{indexS.texture}(currentTexture).paramS.clusterPromFlag = clustPromFlg;
planC{indexS.texture}(currentTexture).paramS.haralCorrFlg = haralCorrFlg;

planC{indexS.texture}(currentTexture).description = descript;
planC{indexS.texture}(currentTexture).patchSize = patchSizeV;
planC{indexS.texture}(currentTexture).patchUnit = patchUnit;

% Create Texture Scans
[xVals, yVals, zVals] = getScanXYZVals(planC{indexS.scan}(scanNum));
deltaXYZv(1) = abs(xVals(2)-xVals(1));
deltaXYZv(2) = abs(yVals(2)-yVals(1));
deltaXYZv(3) = abs(zVals(2)-zVals(1));
zV = zVals(uniqueSlices);
regParamsS.horizontalGridInterval = deltaXYZv(1);
regParamsS.verticalGridInterval   = deltaXYZv(2); %(-)ve for dose
regParamsS.coord1OFFirstPoint   = xVals(minc);
%regParamsS.coord2OFFirstPoint   = yVals(minr); % for dose
regParamsS.coord2OFFirstPoint   = yVals(maxr);
regParamsS.zValues  = zV;
regParamsS.sliceThickness = [planC{indexS.scan}(scanNum).scanInfo(uniqueSlices).sliceThickness];
assocTextureUID = planC{indexS.texture}(currentTexture).textureUID;
%dose2CERR(entropy3M,[], 'entropy3voxls_Ins3_NI14','test','test','non CT',regParamsS,'no',assocScanUID)
if ~isempty(energy3M)
    planC = scan2CERR(energy3M,'Energy','Passed',regParamsS,assocTextureUID,planC);
end
if ~isempty(entropy3M)
    planC = scan2CERR(entropy3M,'Entropy','Passed',regParamsS,assocTextureUID,planC);
end
if ~isempty(sumAvg3M)
    planC = scan2CERR(sumAvg3M,'Sum Average','Passed',regParamsS,assocTextureUID,planC);
end
if ~isempty(corr3M)
    planC = scan2CERR(corr3M,'Correlation','Passed',regParamsS,assocTextureUID,planC);
end
if ~isempty(invDiffMom3M)
    planC = scan2CERR(invDiffMom3M,'Homogenity','Passed',regParamsS,assocTextureUID,planC);
end
if ~isempty(contrast3M)
    planC = scan2CERR(contrast3M,'Contrast','Passed',regParamsS,assocTextureUID,planC);
end
if ~isempty(clustShade3M)
    planC = scan2CERR(clustShade3M,'Cluster Shade','Passed',regParamsS,assocTextureUID,planC);
end
if ~isempty(clustPromin3M)
    planC = scan2CERR(clustPromin3M,'Cluster Prominance','Passed',regParamsS,assocTextureUID,planC);
end
if ~isempty(haralCorr3M)
    planC = scan2CERR(haralCorr3M,'Haralick Correlation','Passed',regParamsS,assocTextureUID,planC);
end
