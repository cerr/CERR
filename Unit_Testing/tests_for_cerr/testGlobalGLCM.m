% this script tests global GLCM texture features between CERR and ITK.
%
% APA, 11/28/2016

% Number of Gray levels
nL = 4;

% Random n x n x n matrix
n = 10;
testM = rand(n,n,n);
testM = imquantize_cerr(testM,nL);

% Structure from planC
global planC
indexS = planC{end};
scanNum     = 1;
structNum   = 16;

[rasterSegments, planC, isError]    = getRasterSegments(structNum,planC);
[mask3M, uniqueSlices]              = rasterToMask(rasterSegments, scanNum, planC);
scanArray3M                         = getScanArray(planC{indexS.scan}(scanNum));

SUVvals3M                           = mask3M.*double(scanArray3M(:,:,uniqueSlices));
[minr, maxr, minc, maxc, mins, maxs]= compute_boundingbox(mask3M);
maskBoundingBox3M                   = mask3M(minr:maxr,minc:maxc,mins:maxs);
volToEval                           = SUVvals3M(minr:maxr,minc:maxc,mins:maxs);
volToEval(maskBoundingBox3M==0)     = NaN;

testM = imquantize_cerr(volToEval,nL);


% CERR texture
flagS.energy = 1;
flagS.entropy = 1;
flagS.corr = 1;
flagS.haralickCorr = 1;
flagS.clustShade = 1;
flagS.clustProm = 1;
flagS.contrast = 1;
flagS.invDiffMoment = 1;
flagS.sumAvg = 1;

tic
cooccurType = 2; % generates separate cooccurrance matrix for each direction.
offsetsM = getOffsets(1); 
cooccurM = calcCooccur(testM, offsetsM, nL, cooccurType);% Note: cooccurM is 
% ... of size (nLxnL, number of directions)
featureS = cooccurToScalarFeatures(cooccurM, flagS);
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
system([fullfile(globalGlcmDir,'GlobalGlcmFeatures'), ' ', scanFileName, ' 4 1 4 ', maskFileName])
toc
fileC = file2cell('GlobalGlCMfeatures.txt');

% feature order from ITK:
% Energy, Entropy, Correlation, InverseDifferenceMoment, Inertia, ClusterShade
% ClusterProminence, HaralickCorrelation
featuresM = [];
for off = 1:13
    featuresM(off,:) = strread(fileC{off*2});
end
orderV = [11, 13, 10, 12, 5, 8, 9, 7, 6, 4, 1, 2, 3]; % map direction order ...
% ... between CERR and ITK.
maxEnergyDiff = max(abs((featuresM(orderV,1) - featureS.energy')./featureS.energy'*100));
maxEntropyDiff = max(abs((featuresM(orderV,2) - featureS.entropy')./featureS.entropy'*100));
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

