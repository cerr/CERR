% this script tests NGTDM features between CERR and pyradiomics.
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

% Number of voxels
numVoxels = numel(testM);

scanType = 'original';
%generate results from pyradiomics
teststruct = PyradWrapper(testM, maskBoundingBox3M, scanType);

%% CERR NGTDM features

[s,p] = calcNGTDM(testM, [1, 1, 1], nL);
ngtdmS = ngtdmToScalarFeatures(s,p,numVoxels);

cerrNgtdmV = [ngtdmS.busyness ngtdmS.coarseness ngtdmS.complexity ngtdmS.contrast ngtdmS.strength];
