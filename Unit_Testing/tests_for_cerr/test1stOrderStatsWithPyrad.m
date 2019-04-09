% this script tests 1st Order Statistics features between CERR and pyradiomics.
%
% RKP, 03/22/2018



firstOrderParamFileName = fullfile(fileparts(fileparts(getCERRPath)),...
    'Unit_Testing','tests_for_cerr','test_first_order_radiomics_extraction_settings.json');
cerrFileName = fullfile(fileparts(fileparts(getCERRPath)),...
    'Unit_Testing','data_for_cerr_tests','CERR_plans','head_neck_ex1_20may03.mat.bz2');

planC = loadPlanC(cerrFileName,tempdir);
indexS = planC{end};

paramS = getRadiomicsParamTemplate(firstOrderParamFileName);
strNum = getMatchingIndex(paramS.structuresC{1},{planC{indexS.structures}.structureName});
scanNum = getStructureAssociatedScan(strNum,planC);

%% Calculate features using CERR

firstOrderS = calcGlobalRadiomicsFeatures...
            (scanNum, strNum, paramS, planC);
firstOrderS = firstOrderS.Original.firstOrderS;
cerrFirstOrderV = [firstOrderS.energy, firstOrderS.totalEnergy, firstOrderS.interQuartileRange, ...
    firstOrderS.kurtosis+3, firstOrderS.max, firstOrderS.mean, firstOrderS.meanAbsDev, ...
    firstOrderS.median, firstOrderS.medianAbsDev, firstOrderS.min, ...
    firstOrderS.P10, firstOrderS.P90, firstOrderS.interQuartileRange, ...
    firstOrderS.robustMeanAbsDev, firstOrderS.rms, firstOrderS.skewness, ...
    firstOrderS.std, firstOrderS.var, firstOrderS.entropy];

%% Calculate features using pyradiomics

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

pyradFirstorderNamC = {'Energy', 'TotalEnergy','InterquartileRange','Kurtosis',...
    'Maximum', 'Mean','MeanAbsoluteDeviation','Median','medianAbsDev',...
    'Minimum','10Percentile','90Percentile','InterquartileRange',...
    'RobustMeanAbsoluteDeviation','RootMeanSquared','Skewness',...
    'StandardDeviation','Variance','Entropy'};

pyradFirstorderNamC = strcat(['original', '_firstorder_'],pyradFirstorderNamC);

pyRadFirstOrderV = [];
for i = 1:length(pyradFirstorderNamC)
    if isfield(teststruct,pyradFirstorderNamC{i})
        pyRadFirstOrderV(i) = teststruct.(pyradFirstorderNamC{i});
    else
        pyRadFirstOrderV(i) = NaN;
    end
end

diffFirstOrderV = (cerrFirstOrderV - pyRadFirstOrderV) ./ cerrFirstOrderV * 100