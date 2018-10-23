% this script tests global GLCM texture features between CERR and ITK.
%
% APA, 11/28/2016

% Number of Gray levels
nL = 4;

voxelOffset = 1;
dirFlag = 1;

% Random n x n x n matrix
n = 10;
testM = rand(n,n,n);
testM = imquantize_cerr(testM,nL);
maskBoundingBox3M = testM .^ 0;

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


% % CERR texture
% flagS.energy = 1;
% flagS.entropy = 1;
% flagS.corr = 1;
% flagS.haralickCorr = 1;
% flagS.clustShade = 1;
% flagS.clustProm = 1;
% flagS.contrast = 1;
% flagS.invDiffMoment = 1;
% flagS.sumAvg = 1;

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


tic
cooccurType = 2; % generates separate cooccurrance matrix for each direction.
offsetsM = getOffsets(dirFlag) * voxelOffset; 
offsetsM = offsetsM(1:2,:);
cooccurM = calcCooccur(testM, offsetsM, nL, cooccurType);% Note: cooccurM is 
% ... of size (nLxnL, number of directions)
featureS = cooccurToScalarFeatures(cooccurM, glcmFlagS);
toc

%% ITK texture
cerrTestDir = getCERRPath;
cerrTestDir(end) = [];
if ispc
    slashType = '\';
else
    slashType = '/';
end
slashV = strfind(cerrTestDir, slashType);
cerrTestDir = cerrTestDir(1:slashV(end)-1);
cerrTestDir = fullfile(cerrTestDir,'Unit_Testing','tests_for_cerr');

globalGlcmDir = fullfile(cerrTestDir,'GlobalGlcmFeatures','win7');
resolution = [15 15 15]; % dummy resolution.
offset = [0 0 0];
scanFileName = fullfile(cerrTestDir,'mhaData','test1.mha');
maskFileName = fullfile(cerrTestDir,'mhaData','testMask1.mha');
test1M = permute(testM, [2 1 3]); % required to match coordinate system ...
%... between CERR and DICOm
test1M = flipdim(test1M,3);
mask1M = permute(maskBoundingBox3M, [2 1 3]);
mask1M = flipdim(mask1M,3);
delete(scanFileName)
delete(maskFileName)
writemetaimagefile(scanFileName, (test1M), resolution, offset)
writemetaimagefile(maskFileName, mask1M, resolution, offset)

% run ITK's textutre calculation
cd(globalGlcmDir)
tic
% system([fullfile(globalGlcmDir,'GlobalGlcmFeatures'), ' ', scanFileName, ' 4 1 4 ', maskFileName])
system([fullfile(globalGlcmDir,'GlobalGlcmFeatures'), ' ', scanFileName, ' ',...
    num2str(nL), ' ', num2str(1), ' ', num2str(nL), ' ', maskFileName])
toc
fileC = file2cell('GlobalGlCMfeatures.txt');

% feature order from ITK:
% Energy, Entropy, Correlation, InverseDifferenceMoment, Inertia, ClusterShade
% ClusterProminence, HaralickCorrelation
featuresM = [];
for off = 1:size(offsetsM,1)
    featuresM(off,:) = strread(fileC{off*2});
end
orderV = [11, 13, 10, 12, 5, 8, 9, 7, 6, 4, 1, 2, 3]; % map direction order ...
% ... between CERR and ITK.
maxEnergyDiff = max(abs((featuresM(orderV,1) - featureS.energy')./featureS.energy'*100));
maxEntropyDiff = max(abs((featuresM(orderV,2) - featureS.jointEntropy')./featureS.jointEntropy'*100));
maxInvDiffMomDiff = max(abs((featuresM(orderV,4) - featureS.invDiffMom')./featureS.invDiffMom'*100));
maxContrastDiff = max(abs((featuresM(orderV,5) - featureS.contrast')./featureS.contrast'*100));
maxClustShadeDiff = max(abs((featuresM(orderV,6) - featureS.clustShade')./featureS.clustShade'*100));
maxClustPromDiff = max(abs((featuresM(orderV,7) - featureS.clustPromin')./featureS.clustPromin'*100));

disp('========= Maximum difference between features for all 13 directions ==========')
disp(['Energy: ', sprintf('%0.1e',maxEnergyDiff), ' %'])
disp(['Entropy: ', sprintf('%0.1e',maxEntropyDiff), ' %'])
disp(['Inverse Difference Moment: ', sprintf('%0.1e',maxInvDiffMomDiff), ' %'])
disp(['Contrast: ', sprintf('%0.1e',maxContrastDiff), ' %'])
disp(['Cluster Shade: ', sprintf('%0.1e',maxClustShadeDiff), ' %'])
disp(['Cluster Prominance: ', sprintf('%0.1e',maxClustPromDiff), ' %'])

