% this script tests GLCM features between CERR and pyradiomics on a wavelet filtered image.
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


scanType = 'wavelet';
dirString = 'HHH';

%% Calculate features using CERR
harFeat3DdirS = calcGlobalRadiomicsFeatures...
            (scanNum, strNum, paramS, planC);
harlCombS = harFeat3DdirS.Wavelets_Coif1__HHH.glcmFeatS.AvgS;
cerrGlcmV = [harlCombS.autoCorr, harlCombS.jointAvg, harlCombS.clustPromin, harlCombS.clustShade, harlCombS.clustTendency, ...
harlCombS.contrast, harlCombS.corr, harlCombS.diffAvg, harlCombS.diffEntropy, harlCombS.diffVar, harlCombS.dissimilarity, ...
harlCombS.energy, harlCombS.jointEntropy, harlCombS.invDiff, harlCombS.invDiffMom, harlCombS.firstInfCorr, ...
harlCombS.secondInfCorr, harlCombS.invDiffMomNorm, harlCombS.invDiffNorm, harlCombS.invVar, ...
harlCombS.sumAvg, harlCombS.sumEntropy, harlCombS.sumVar];

% %% Calculate features using pyradiomics
% % image and mask for a structure
% testM = single(planC{indexS.scan}(scanNum).scanArray) - ...
%     single(planC{indexS.scan}(scanNum).scanInfo(1).CTOffset);
% mask3M = zeros(size(testM),'logical');
% [rasterSegments, planC, isError] = getRasterSegments(strNum,planC);
% [maskBoundBox3M, uniqueSlices] = rasterToMask(rasterSegments, scanNum, planC);
% mask3M(:,:,uniqueSlices) = maskBoundBox3M;
% 
% dx = planC{indexS.scan}(scanNum).scanInfo(1).grid1Units;
% dy = planC{indexS.scan}(scanNum).scanInfo(1).grid1Units;
% dz = mode(diff([planC{indexS.scan}(scanNum).scanInfo(:).zValue]));
% pixelSize = [dx dy dz]*10;
% 
% teststruct = PyradWrapper(testM, mask3M, pixelSize, scanType, dirString);
% 
% %teststruct = PyradWrapper(testM, mask3M, scanType, dirString);
% pyradGlcmNamC = {'Autocorrelation', 'JointAverage', 'ClusterProminence', 'ClusterShade',  'ClusterTendency', ...
%     'Contrast', 'Correlation', 'DifferenceAverage', 'DifferenceEntropy', 'DifferenceVariance', 'Dissimilarity', ...
%     'JointEnergy', 'JointEntropy','Id','Idm', 'Imc1' , ...
%     'Imc2', 'Idmn','Idn','InverseVariance', 'sumAverage', 'SumEntropy', 'sumVariance'};
% 
% pyradGlcmNamC = strcat(['wavelet','_', dirString,'_glcm_'],pyradGlcmNamC);
% pyRadGlcmV = [];
% for i = 1:length(pyradGlcmNamC)
%     if isfield(teststruct,pyradGlcmNamC{i})
%         pyRadGlcmV(i) = teststruct.(pyradGlcmNamC{i});
%     else
%         pyRadGlcmV(i) = NaN;
%     end
% end
% 
% %% Compare
% glcmDiffV = (cerrGlcmV - pyRadGlcmV) ./ cerrGlcmV * 100

%% Compare using previously calculated values of pyradiomics glcm
saved_pyRadGlcmV = [929.516284841440,30.4950632056943,5316.83199378276,-0.303806680516285,20.9971321089971,22.7275310589439,-0.0380659828547803,2.78099962843313,3.04970358686672,14.7880425011987,NaN,0.0446949242970363,6.28336538646016,0.479852104826365,0.424210035556516,-0.0921069324860780,0.664903434331990,0.993049866792659,0.955511453133062,0.367836063144979,NaN,3.75942560575858,NaN];
glcmDiffV = (cerrGlcmV - saved_pyRadGlcmV) ./ cerrGlcmV * 100
