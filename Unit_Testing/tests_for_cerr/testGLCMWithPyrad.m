% this script tests GLCM features between CERR and pyradiomics.
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

%% CERR GLCM features

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
harFeat3DdirS = get_haralick(dirctn, cooccurType, testM, ...
nL, glcmFlagS);

% harlCombS = featureS.harFeat3DcombS.CombS;
harlCombS = harFeat3DdirS.AvgS;
cerrGlcmV = [harlCombS.autoCorr, harlCombS.jointAvg, harlCombS.clustPromin, harlCombS.clustShade, harlCombS.clustTendency, ...
harlCombS.contrast, harlCombS.corr, harlCombS.diffAvg, harlCombS.diffEntropy, harlCombS.diffVar, harlCombS.dissimilarity, ...
harlCombS.energy, harlCombS.jointEntropy, harlCombS.invDiff, harlCombS.invDiffMom, harlCombS.firstInfCorr, ...
harlCombS.secondInfCorr, harlCombS.invDiffMomNorm, harlCombS.invDiffNorm, harlCombS.invVar, ...
harlCombS.sumAvg, harlCombS.sumEntropy, harlCombS.sumVar];

pyradGlcmNamC = {'Autocorrelation', 'JointAverage', 'ClusterProminence', 'ClusterShade',  'ClusterTendency', ...
    'Contrast', 'Correlation', 'DifferenceAverage', 'DifferenceEntropy', 'DifferenceVariance', 'Dissimilarity', ...
    'JointEnergy', 'JointEntropy','Id','Idm', 'Imc1' , ...
    'Imc2', 'Idmn','Idn','InverseVariance', 'sumAverage', 'SumEntropy', 'sumVariance'};

    pyradGlcmNamC = strcat(['original','_glcm_'],pyradGlcmNamC);


pyRadGlcmV = [];
for i = 1:length(pyradGlcmNamC)
    if isfield(teststruct,pyradGlcmNamC{i})
        pyRadGlcmV(i) = teststruct.(pyradGlcmNamC{i});
    else
        pyRadGlcmV(i) = NaN;
    end
end

glcmDiffV = (cerrGlcmV - pyRadGlcmV) ./ cerrGlcmV * 100