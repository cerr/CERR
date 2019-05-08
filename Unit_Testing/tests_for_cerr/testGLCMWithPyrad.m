% this script tests GLCM features between CERR and pyradiomics.
%
% RKP, 03/22/2018

%% Load image
glcmParamFileName = fullfile(fileparts(fileparts(getCERRPath)),...
    'Unit_Testing','tests_for_cerr','test_glcm_radiomics_extraction_settings.json');
cerrFileName = fullfile(fileparts(fileparts(getCERRPath)),...
    'Unit_Testing','data_for_cerr_tests','CERR_plans','head_neck_ex1_20may03.mat.bz2');

planC = loadPlanC(cerrFileName,tempdir);
indexS = planC{end};

paramS = getRadiomicsParamTemplate(glcmParamFileName);
strNum = getMatchingIndex(paramS.structuresC{1},{planC{indexS.structures}.structureName});
scanNum = getStructureAssociatedScan(strNum,planC);

%% Calculate features using CERR
harFeat3DdirS = calcGlobalRadiomicsFeatures...
            (scanNum, strNum, paramS, planC);
harlCombS = harFeat3DdirS.Original.glcmFeatS.AvgS;
cerrGlcmV = [harlCombS.autoCorr, harlCombS.jointAvg, harlCombS.clustPromin, harlCombS.clustShade, harlCombS.clustTendency, ...
harlCombS.contrast, harlCombS.corr, harlCombS.diffAvg, harlCombS.diffEntropy, harlCombS.diffVar, harlCombS.dissimilarity, ...
harlCombS.energy, harlCombS.jointEntropy, harlCombS.invDiff, harlCombS.invDiffMom, harlCombS.firstInfCorr, ...
harlCombS.secondInfCorr, harlCombS.invDiffMomNorm, harlCombS.invDiffNorm, harlCombS.invVar, ...
harlCombS.sumAvg, harlCombS.sumEntropy, harlCombS.sumVar];

%% Calculate features using pyradiomics
% image and mask for a structure
testM = single(planC{indexS.scan}(scanNum).scanArray) - ...
    single(planC{indexS.scan}(scanNum).scanInfo(1).CTOffset);
mask3M = zeros(size(testM),'logical');
[rasterSegments, planC, isError] = getRasterSegments(strNum,planC);
[maskBoundBox3M, uniqueSlices] = rasterToMask(rasterSegments, scanNum, planC);
mask3M(:,:,uniqueSlices) = maskBoundBox3M;


scanType = 'original';
dx = planC{indexS.scan}(scanNum).scanInfo(1).grid1Units;
dy = planC{indexS.scan}(scanNum).scanInfo(1).grid1Units;
dz = mode(diff([planC{indexS.scan}(scanNum).scanInfo(:).zValue]));
pixelSize = [dx dy dz]*10;

teststruct = PyradWrapper(testM, mask3M, pixelSize, scanType, dirString);

%teststruct = PyradWrapper(testM, mask3M, scanType);
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

%% Compare
glcmDiffV = (cerrGlcmV - pyRadGlcmV) ./ cerrGlcmV * 100

%% Compare using previously calculated values of pyradiomics glcm
saved_pyRadGlcmV = [1751.49603382875,40.8299981390930,1699291.05899833,-11302.3472463506,399.183404315141,61.6492931961095,0.731298422981024,3.58225481213654,3.08032041137040,48.5207221130057,NaN,0.0325243174278277,6.85603719995355,0.522724816541355,0.480259668311807,-0.208253976228619,0.884543363584260,0.995164157047163,0.971313972188856,0.373754218660873,NaN,4.82370970733959,NaN];
glcmDiffV = (cerrGlcmV - saved_pyRadGlcmV) ./ cerrGlcmV * 100
