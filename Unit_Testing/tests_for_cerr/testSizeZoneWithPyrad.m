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

scanType = 'original';
%generate results from pyradiomics
teststruct = PyradWrapper(testM, maskBoundingBox3M, scanType);

%% Size Zone features in 3d for CERR

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
flagS.lahgle = 1;

szmType = 1; % 1: 3d, 2: 2d
szmM = calcSZM(testM, nL, szmType);
numVoxels = sum(~isnan(testM(:)));
szmS = szmToScalarFeatures(szmM,numVoxels, flagS);

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