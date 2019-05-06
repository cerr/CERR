% this script tests 1st Order Statistics features between CERR and pyradiomics on a Wavelet filetered image.
%
% RKP, 03/22/2018


%% Load image
firstOrderParamFileName = fullfile(fileparts(fileparts(getCERRPath)),...
    'Unit_Testing','tests_for_cerr','test_first_order_radiomics_extraction_settings.json');
cerrFileName = fullfile(fileparts(fileparts(getCERRPath)),...
    'Unit_Testing','data_for_cerr_tests','CERR_plans','head_neck_ex1_20may03.mat.bz2');

planC = loadPlanC(cerrFileName,tempdir);
indexS = planC{end};

paramS = getRadiomicsParamTemplate(firstOrderParamFileName);
strNum = getMatchingIndex(paramS.structuresC{1},{planC{indexS.structures}.structureName});
scanNum = getStructureAssociatedScan(strNum,planC);

%wavType = 'coif1';
%scanType = 'Original';
scanType = 'Wavelet';
%dirString = 'HLH';
dirString = paramS.imageType.Wavelets.Direction.val;

%% Calculate features using CERR

firstOrderS = calcGlobalRadiomicsFeatures...
            (scanNum, strNum, paramS, planC);
firstOrderS = firstOrderS.(['Wavelets_coif_1_',dirString]).firstOrderS;
cerrFirstOrderV = [firstOrderS.energy, firstOrderS.totalEnergy, firstOrderS.interQuartileRange, ...
    firstOrderS.kurtosis+3, firstOrderS.max, firstOrderS.mean, firstOrderS.meanAbsDev, ...
    firstOrderS.median, firstOrderS.medianAbsDev, firstOrderS.min, ...
    firstOrderS.P10, firstOrderS.P90, firstOrderS.interQuartileRange, ...
    firstOrderS.robustMeanAbsDev, firstOrderS.rms, firstOrderS.skewness, ...
    firstOrderS.std, firstOrderS.var, firstOrderS.entropy];

% %% Calculate features using pyradiomics
% 
% testM = single(planC{indexS.scan}(scanNum).scanArray) - ...
%     single(planC{indexS.scan}(scanNum).scanInfo(1).CTOffset);
% mask3M = zeros(size(testM),'logical');
% [rasterSegments, planC, isError] = getRasterSegments(strNum,planC);
% [maskBoundBox3M, uniqueSlices] = rasterToMask(rasterSegments, scanNum, planC);
% mask3M(:,:,uniqueSlices) = maskBoundBox3M;
% dx = planC{indexS.scan}(scanNum).scanInfo(1).grid1Units;
% dy = planC{indexS.scan}(scanNum).scanInfo(1).grid1Units;
% dz = mode(diff([planC{indexS.scan}(scanNum).scanInfo(:).zValue]));
% pixelSize = [dx dy dz]*10;
% teststruct = PyradWrapper(testM, mask3M, pixelSize, scanType, dirString);
% 
% pyradFirstorderNamC = {'Energy', 'TotalEnergy','InterquartileRange','Kurtosis',...
%     'Maximum', 'Mean','MeanAbsoluteDeviation','Median','medianAbsDev',...
%     'Minimum','10Percentile','90Percentile','InterquartileRange',...
%     'RobustMeanAbsoluteDeviation','RootMeanSquared','Skewness',...
%     'StandardDeviation','Variance','Entropy'};
% 
% pyradFirstorderNamC = strcat(['wavelet', '_', dirString, '_firstorder_'],pyradFirstorderNamC);
% %pyradFirstorderNamC = strcat(['original', '_firstorder_'],pyradFirstorderNamC);
% 
% pyRadFirstOrderV = [];
% for i = 1:length(pyradFirstorderNamC)
%     if isfield(teststruct,pyradFirstorderNamC{i})
%         pyRadFirstOrderV(i) = teststruct.(pyradFirstorderNamC{i});
%     else
%         pyRadFirstOrderV(i) = NaN;
%     end
% end
% 
% %% Compare
% diffFirstOrderV = (cerrFirstOrderV - pyRadFirstOrderV) ./ cerrFirstOrderV * 100

%% Compare with previously calculated values of pyradiomics first order features
saved_pyRadFirstOrderV = [87498183.4756395,1049978201.70767,30.4772882461548,16.3069672735214,836.854187011719,-0.191955631352121,48.4171827693622,0.0908048748970032,NaN,-718.366882324219,-73.1680297851562,64.9023208618165,30.4772882461548,16.4187532424825,96.2495122333083,0.546840923205712,NaN,9263.93175818536,3.17432864851443];
diffFirstOrderV = (cerrFirstOrderV - saved_pyRadFirstOrderV) ./ cerrFirstOrderV * 100