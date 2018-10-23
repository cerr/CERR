% this script tests run length texture features between CERR and pyradiomics.
%
% RKP, 03/22/2018

% Number of Gray levels
% nL = 16;
% 
% % Random n x n x n matrix
% n = 20;
% testM = rand(n,n,5);
% testM = imquantize_cerr(testM,nL);
% maskBoundingBox3M = testM .^0;

scanNum = 1;
strNum = 1;
testM = single(planC{indexS.scan}(scanNum).scanArray) - planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;
maskBoundingBox3M = getUniformStr(strNum);
testQuantM = testM;
testQuantM(~maskBoundingBox3M) = NaN;
testQuantM = imquantize_cerr(testQuantM,[],[],[],25);
nL = max(testQuantM(:));

scanType = 'original';
%generate results from pyradiomics
teststruct = PyradWrapper(testM, maskBoundingBox3M, scanType);


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

%% CERR RLM features

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

%numGrLevels = paramS.higherOrderParamS.numGrLevels;

% Number of Gray levels
nL = 16;

% Number of voxels
numVoxels = numel(testM);


% 3D Run-Length features from combined run length matrix
dirctn      = 1;
rlmType     = 2;
rlmFeat3DdirS = get_rlm(dirctn, rlmType, maskBoundingBox3M, ...
    nL, numVoxels, rlmFlagS);

rlmCombS = rlmFeat3DdirS.AvgS;
cerrRlmV = [rlmCombS.gln, rlmCombS.glnNorm, rlmCombS.glv, rlmCombS.hglre, rlmCombS.lglre, rlmCombS.lre, rlmCombS.lrhgle, ...
    rlmCombS.lrlgle, rlmCombS.rln, rlmCombS.rlnNorm, rlmCombS.rlv, rlmCombS.rp, ...
    rlmCombS.sre, rlmCombS.srhgle, rlmCombS.srlgle];

pyradRlmNamC = {'GrayLevelNonUniformity', 'GrayLevelNonUniformityNormalized',...
    'GrayLevelVariance', 'HighGrayLevelRunEmphasis',  'LowGrayLevelRunEmphasis', ...
    'LongRunEmphasis', 'LongRunHighGrayLevelEmphasis', 'LongRunLowGrayLevelEmphasis',...
    'RunLengthNonUniformity', 'RunLengthNonUniformityNormalized', 'RunVariance', ...
    'RunPercentage', 'ShortRunEmphasis','ShortRunHighGrayLevelEmphasis', ...
    'ShortRunLowGrayLevelEmphasis'};

pyradRlmNamC = strcat(['original','_glrlm_'],pyradRlmNamC);

pyRadRlmV = [];
for i = 1:length(pyradRlmNamC)
    if isfield(teststruct,pyradRlmNamC{i})
        pyRadRlmV(i) = teststruct.(pyradRlmNamC{i});
    else
        pyRadRlmV(i) = NaN;
    end
end

rlmDiffV = (cerrRlmV - pyRadRlmV) ./ cerrRlmV * 100