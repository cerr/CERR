% this script tests Size Zone features between CERR and pyradiomics.
%
% RKP, 03/22/2018

%% Load image
sizeZoneParamFileName = fullfile(fileparts(fileparts(getCERRPath)),...
    'Unit_Testing','tests_for_cerr','test_size_zone_radiomics_extraction_settings.json');
cerrFileName = fullfile(fileparts(fileparts(getCERRPath)),...
    'Unit_Testing','data_for_cerr_tests','CERR_plans','head_neck_ex1_20may03.mat.bz2');

planC = loadPlanC(cerrFileName,tempdir);
indexS = planC{end};

paramS = getRadiomicsParamTemplate(sizeZoneParamFileName);
strNum = getMatchingIndex(paramS.structuresC{1},{planC{indexS.structures}.structureName});
scanNum = getStructureAssociatedScan(strNum,planC);

%% Calculate features using CERR

szmS = calcGlobalRadiomicsFeatures...
            (scanNum, strNum, paramS, planC);



szmS = szmS.Original.szmFeatS;


cerrSzmV = [szmS.gln, szmS.glnNorm, szmS.glv, szmS.hglze, szmS.lglze, szmS.lae, szmS.lahgle, ...
    szmS.lalgle, szmS.szn, szmS.sznNorm, szmS.szv, szmS.zp, ...
    szmS.sae, szmS.sahgle, szmS.salgle, szmS.ze];


% %% Calculate features using pyradiomics
% 
% testM = single(planC{indexS.scan}(scanNum).scanArray) - ...
%     single(planC{indexS.scan}(scanNum).scanInfo(1).CTOffset);
% mask3M = zeros(size(testM),'logical');
% [rasterSegments, planC, isError] = getRasterSegments(strNum,planC);
% [maskBoundBox3M, uniqueSlices] = rasterToMask(rasterSegments, scanNum, planC);
% mask3M(:,:,uniqueSlices) = maskBoundBox3M;
% 
% scanType = 'original';
% dx = planC{indexS.scan}(scanNum).scanInfo(1).grid1Units;
% dy = planC{indexS.scan}(scanNum).scanInfo(1).grid1Units;
% dz = mode(diff([planC{indexS.scan}(scanNum).scanInfo(:).zValue]));
% pixelSize = [dx dy dz]*10;
% 
% teststruct = PyradWrapper(testM, mask3M, pixelSize, scanType, dirString);
% %teststruct = PyradWrapper(testM, mask3M, scanType);
% 
% pyradSzmNamC = {'GrayLevelNonUniformity', 'GrayLevelNonUniformityNormalized',...
%     'GrayLevelVariance', 'HighGrayLevelZoneEmphasis',  'LowGrayLevelZoneEmphasis', ...
%     'LargeAreaEmphasis', 'LargeAreaHighGrayLevelEmphasis', 'LargeAreaLowGrayLevelEmphasis',...
%     'SizeZoneNonUniformity', 'SizeZoneNonUniformityNormalized', 'ZoneVariance', ...
%     'ZonePercentage', 'SmallAreaEmphasis','SmallAreaHighGrayLevelEmphasis', ...
%     'SmallAreaLowGrayLevelEmphasis', 'ZoneEntropy'};
% 
% pyradSzmNamC = strcat(['original', '_glszm_'],pyradSzmNamC);
% 
% pyRadSzmV = [];
% for i = 1:length(pyradSzmNamC)
%     if isfield(teststruct,pyradSzmNamC{i})
%         pyRadSzmV(i) = teststruct.(pyradSzmNamC{i});
%     else
%         pyRadSzmV(i) = NaN;
%     end
% end
% 
% %% Comparison of pyradiomics size zone vector with CERR's
% szmDiffV = (cerrSzmV - pyRadSzmV) ./ cerrSzmV * 100

%% Comparison of previously calculated pyradiomics size zone vector with CERR's
saved_pyRadSzmV = [36.7092819614711,0.0214298201759901,347.680051057261,2155.09632224168,0.00772786214050312,5645.66900175131,10069528.4273205,12.4092677586083,973.999416228838,0.568592770711523,5615.26790870541,0.181365802011646,0.781168839292702,1738.84926329545,0.00456792375062457,7.20864310737143];
szmDiffV = (cerrSzmV - saved_pyRadSzmV) ./ cerrSzmV * 100