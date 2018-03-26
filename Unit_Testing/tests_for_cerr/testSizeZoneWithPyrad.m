% this script tests Size Zone features between CERR and pyradiomics.
%
% RKP, 03/22/2018



% % Structure from planC
% global planC
% indexS = planC{end};
% scanNum     = 1;
% structNum   = 16;
% 
% [rasterSegments, planC, isError]    = getRasterSegments(structNum,planC);
% [mask3M, uniqueSlices]              = rasterToMask(rasterSegments, scanNum, planC);
% scanArray3M                         = getScanArray(planC{indexS.scan}(scanNum));
% 
% SUVvals3M                           = mask3M.*double(scanArray3M(:,:,uniqueSlices));
% [minr, maxr, minc, maxc, mins, maxs]= compute_boundingbox(mask3M);
% maskBoundingBox3M                   = mask3M(minr:maxr,minc:maxc,mins:maxs);
% volToEval                           = SUVvals3M(minr:maxr,minc:maxc,mins:maxs);
% volToEval(maskBoundingBox3M==0)     = NaN;
% 
% testM = imquantize_cerr(volToEval,nL);

% Number of Gray levels
nL = 16;

% Random n x n x n matrix
n = 20;
testM = rand(n,n,5);
testM = imquantize_cerr(testM,nL);
maskBoundingBox3M = testM .^0;

%generate results from pyradiomics
teststruct = PyradWrapper(testM, maskBoundingBox3M);

%% Size Zone features in 3d for CERR

szmFlagS.sae = 1;
szmFlagS.lae = 1;
szmFlagS.gln = 1;
szmFlagS.glv = 1;
szmFlagS.szv = 1;
szmFlagS.glnNorm = 1;
szmFlagS.szn = 1;
szmFlagS.sznNorm = 1;
szmFlagS.zp = 1;
szmFlagS.lglze = 1;
szmFlagS.hglze = 1;
szmFlagS.salgle = 1;
szmFlagS.sahgle = 1;
szmFlagS.larhgle = 1;
szmFlagS.lahgle = 1;
szmFlagS.lalgle = 1;

szmType = 1; % 1: 3d, 2: 2d
szmM = calcSZM(testM, nL, szmType);
numVoxels = sum(~isnan(testM(:)));
szmS = szmToScalarFeatures(szmM,numVoxels, szmFlagS);

% cerrSzmV = [szmS.gln, szmS.glnNorm, szmS.glv, szmS.hglre, szmS.lglre, szmS.lre, szmS.lrhgle, ...
%     szmS.lrlgle, szmS.rln, szmS.rlnNorm, szmS.rlv, szmS.rp, ...
%     szmS.sre, szmS.srhgle, szmS.srlgle];
cerrSzmV = [szmS.gln, szmS.glnNorm, szmS.glv, szmS.hglze, szmS.lglze, szmS.lae, szmS.lahgle, ...
    szmS.lalgle, szmS.szn, szmS.sznNorm, szmS.szv, szmS.zp, ...
    szmS.sae, szmS.sahgle, szmS.salgle];

pyradSzmNamC = {'GrayLevelNonUniformity', 'GrayLevelNonUniformityNormalized',...
    'GrayLevelVariance', 'HighGrayLevelZoneEmphasis',  'LowGrayLevelZoneEmphasis', ...
    'LargeAreaEmphasis', 'LargeAreaHighGrayLevelEmphasis', 'LargeAreaLowGrayLevelEmphasis',...
    'SizeZoneNonUniformity', 'SizeZoneNonUniformityNormalized', 'ZoneVariance', ...
    'ZonePercentage', 'SmallAreaEmphasis','SmallAreaHighGrayLevelEmphasis', ...
    'SmallAreaLowGrayLevelEmphasis'};

pyradSzmNamC = strcat(['original', '_glszm_'],pyradSzmNamC);

pyRadSzmV = [];
for i = 1:length(pyradSzmNamC)
    if isfield(teststruct,pyradSzmNamC{i})
        pyRadSzmV(i) = teststruct.(pyradSzmNamC{i});
    else
        pyRadSzmV(i) = NaN;
    end
end
szmDiffV = (cerrSzmV - pyRadSzmV) ./ cerrSzmV * 100