% this script tests GLCM features between CERR and pyradiomics.
%
% RKP, 03/22/2018


glcmParamFileName = fullfile(fileparts(fileparts(getCERRPath)),...
    'Unit_Testing','tests_for_cerr','test_glcm_radiomics_extraction_settings.json');
cerrFileName = fullfile(fileparts(fileparts(getCERRPath)),...
    'Unit_Testing','data_for_cerr_tests','CERR_plans','head_neck_ex1_20may03.mat.bz2');

planC = loadPlanC(cerrFileName,tempdir);
indexS = planC{end};

paramS = getRadiomicsParamTemplate(glcmParamFileName);
strNum = getMatchingIndex(paramS.structuresC{1},{planC{indexS.structures}.structureName});
scanNum = getStructureAssociatedScan(strNum,planC);

% Calculate features using CERR
harFeat3DdirS = calcGlobalRadiomicsFeatures...
            (scanNum, strNum, paramS, planC);
harlCombS = harFeat3DdirS.glcmFeatS.AvgS;
cerrGlcmV = [harlCombS.autoCorr, harlCombS.jointAvg, harlCombS.clustPromin, harlCombS.clustShade, harlCombS.clustTendency, ...
harlCombS.contrast, harlCombS.corr, harlCombS.diffAvg, harlCombS.diffEntropy, harlCombS.diffVar, harlCombS.dissimilarity, ...
harlCombS.energy, harlCombS.jointEntropy, harlCombS.invDiff, harlCombS.invDiffMom, harlCombS.firstInfCorr, ...
harlCombS.secondInfCorr, harlCombS.invDiffMomNorm, harlCombS.invDiffNorm, harlCombS.invVar, ...
harlCombS.sumAvg, harlCombS.sumEntropy, harlCombS.sumVar];

% Calculate features using pyradiomics
testM = single(planC{indexS.scan}(scanNum).scanArray) - planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;
maskBoundingBox3M = getUniformStr(strNum);
scanType = 'original';
teststruct = PyradWrapper(testM, maskBoundingBox3M, scanType);
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

glcmDiffV = (cerrGlcmV - pyRadGlcmV) ./ cerrGlcmV * 100;
