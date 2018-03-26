% this script tests NGLDM features between CERR and pyradiomics.
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

%% NGLDM features CERR

patchRadius3dV = [1, 1, 1];
imgDiffThresh = 0;
% 3d
ngldmM = calcNGLDM(testM, patchRadius3dV, ...
    nL, imgDiffThresh);
ngldmS = ngldmToScalarFeatures(ngldmM,numVoxels);

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


pyradNgldmNamC = strcat(['original', '_gldm_'],pyradNgldmNamC);

pyRadNgldmV = [];
for i = 1:length(pyradNgldmNamC)
    if isfield(teststruct,pyradNgldmNamC{i})
        pyRadNgldmV(i) = teststruct.(pyradNgldmNamC{i});
    else
        pyRadNgldmV(i) = NaN;
    end
end

ngldmDiffV = (cerrNgldmV - pyRadNgldmV) ./ cerrNgldmV * 100