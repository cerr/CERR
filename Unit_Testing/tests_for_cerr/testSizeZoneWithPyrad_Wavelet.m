% this script tests Size Zone features between CERR and pyradiomics on a wavelet filtered image.
%
% RKP, 03/22/2018

%% load image
sizeZoneParamFileName = fullfile(fileparts(fileparts(getCERRPath)),...
    'Unit_Testing','tests_for_cerr','test_size_zone_radiomics_extraction_settings.json');
cerrFileName = fullfile(fileparts(fileparts(getCERRPath)),...
    'Unit_Testing','data_for_cerr_tests','CERR_plans','head_neck_ex1_20may03.mat.bz2');

planC = loadPlanC(cerrFileName,tempdir);
indexS = planC{end};

paramS = getRadiomicsParamTemplate(sizeZoneParamFileName);
strNum = getMatchingIndex(paramS.structuresC{1},{planC{indexS.structures}.structureName});
scanNum = getStructureAssociatedScan(strNum,planC);

scanType = 'wavelet';
dirString = 'HHH';

%% Calculate features using CERR

szmS = calcGlobalRadiomicsFeatures...
            (scanNum, strNum, paramS, planC);



szmS = szmS.Wavelets_Coif1__HHH.szmFeatS;


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
% dx = planC{indexS.scan}(scanNum).scanInfo(1).grid1Units;
% dy = planC{indexS.scan}(scanNum).scanInfo(1).grid1Units;
% dz = mode(diff([planC{indexS.scan}(scanNum).scanInfo(:).zValue]));
% pixelSize = [dx dy dz]*10;
% 
% teststruct = PyradWrapper(testM, mask3M, pixelSize, scanType, dirString);
% 
% %teststruct = PyradWrapper(testM, mask3M, scanType, dirString);
% 
% pyradSzmNamC = {'GrayLevelNonUniformity', 'GrayLevelNonUniformityNormalized',...
%     'GrayLevelVariance', 'HighGrayLevelZoneEmphasis',  'LowGrayLevelZoneEmphasis', ...
%     'LargeAreaEmphasis', 'LargeAreaHighGrayLevelEmphasis', 'LargeAreaLowGrayLevelEmphasis',...
%     'SizeZoneNonUniformity', 'SizeZoneNonUniformityNormalized', 'ZoneVariance', ...
%     'ZonePercentage', 'SmallAreaEmphasis','SmallAreaHighGrayLevelEmphasis', ...
%     'SmallAreaLowGrayLevelEmphasis', 'ZoneEntropy'};
% 
% pyradSzmNamC = strcat(['wavelet','_', dirString, '_glszm_'],pyradSzmNamC);
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
% 
% %% Comparison of wavelet processed pyradiomics size zone vector with CERR's
% szmDiffV = (cerrSzmV - pyRadSzmV) ./ cerrSzmV * 100


%% Comparison of wavelet pre-processed previously calculated pyradiomics size zone vector with CERR's
saved_pyRadSzmV = [99.2292609351433,0.0498890200780007,40.1863543135308,966.928104575163,0.00177821537199899,5792.26093514329,5390040.98944193,6.23296837296028,970.669180492710,0.488018693058175,5769.71156797277,0.210587612493383,0.726234798465152,704.061962584404,0.00146164305463294,6.18178582985932];
szmDiffV = (cerrSzmV - saved_pyRadSzmV) ./ cerrSzmV * 100