% this script tests run length texture features between CERR and ITK.
%
% APA, 11/30/2016

% Number of Gray levels
nL = 16;

% Random n x n x n matrix
n = 20;
testM = rand(n,n,5);
testM = imquantize_cerr(testM,nL);
maskBoundingBox3M = testM .^0;

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


% CERR texture
flagS.sre = 1;
flagS.lre = 1;
flagS.gln = 1;
flagS.rln = 1;
flagS.rp = 1;
flagS.lglre = 1;
flagS.hglre = 1;
flagS.srlgle = 1;
flagS.srhgle = 1;
flagS.lrlgle = 1;
flagS.lrhgle = 1;

% Get offsets for all 13 directions
offsetsM = getOffsets(1); 

% Number of voxels
numVoxels = numel(testM);

% Calculate the Run Length Matrix (RLM)
rlmType = 2;
tic,
rlmM = calcRLM(testM, offsetsM, nL, rlmType); % generates separate RLM for each direction.

% Convert RLM matrix to scalar features
featureS = rlmToScalarFeatures(rlmM{1}, numVoxels, flagS);
fnameC = fieldnames(featureS);
for i = 2:size(offsetsM,1)
    featureOffS = rlmToScalarFeatures(rlmM{i}, numVoxels, flagS);
    for j = 1:length(fnameC)
        field = fnameC{j};
        featureS.(field) = [featureS.(field), featureOffS.(field)];
    end
end
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

rlmDir = fullfile(cerrTestDir,'RunLengthFeatures','win7');
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
cd(rlmDir)
tic
system([fullfile(globalGlcmDir,'RunLengthfeatures'), ' ', scanFileName, ' ', num2str(nL),' 1 ',...
    num2str(nL),' ', maskFileName])
toc
fileC = file2cell('RunLengthfeatures.txt');

% feature order from ITK:
% Energy, Entropy, Correlation, InverseDifferenceMoment, Inertia, ClusterShade
% ClusterProminence, HaralickCorrelation
featuresM = [];
for off = 1:13
    featuresM(off,:) = strread(fileC{off*2});
end
orderV = [11, 13, 10, 12, 5, 8, 9, 7, 6, 4, 1, 2, 3]; % map direction order ...
% ... between CERR and ITK.
maxSreDiff = max(abs((featuresM(orderV,1) - featureS.sre')./featureS.sre'*100));
maxLreDiff = max(abs((featuresM(orderV,2) - featureS.lre')./featureS.lre'*100));
maxGlnDiff = max(abs((featuresM(orderV,3) - featureS.gln')./featureS.gln'*100));
maxRlnDiff = max(abs((featuresM(orderV,4) - featureS.rln')./featureS.rln'*100));
maxLglreDiff = max(abs((featuresM(orderV,5) - featureS.lglre')./featureS.lglre'*100));
maxHglreDiff = max(abs((featuresM(orderV,6) - featureS.hglre')./featureS.hglre'*100));
maxSrlgleDiff = max(abs((featuresM(orderV,7) - featureS.srlgle')./featureS.srlgle'*100));
maxSrhgleDiff = max(abs((featuresM(orderV,8) - featureS.srhgle')./featureS.srhgle'*100));
maxLrlgleDiff = max(abs((featuresM(orderV,9) - featureS.lrlgle')./featureS.lrlgle'*100));
maxLrhgleDiff = max(abs((featuresM(orderV,10) - featureS.lrhgle')./featureS.lrhgle'*100));

disp('========= Maximum difference between features for all 13 directions ==========')
disp(['SRE: ', sprintf('%0.1e',maxSreDiff), ' %'])
disp(['LRE: ', sprintf('%0.1e',maxLreDiff), ' %'])
disp(['GLN: ', sprintf('%0.1e',maxGlnDiff), ' %'])
disp(['RLN: ', sprintf('%0.1e',maxRlnDiff), ' %'])
disp(['LGLRE: ', sprintf('%0.1e',maxLglreDiff), ' %'])
disp(['HGLRE: ', sprintf('%0.1e',maxHglreDiff), ' %'])
disp(['SRLGLE: ', sprintf('%0.1e',maxSrlgleDiff), ' %'])
disp(['SRHGLE: ', sprintf('%0.1e',maxSrhgleDiff), ' %'])
disp(['LRLGLE: ', sprintf('%0.1e',maxLrlgleDiff), ' %'])
disp(['LRHGLE: ', sprintf('%0.1e',maxLrhgleDiff), ' %'])


