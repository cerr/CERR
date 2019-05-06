% this script tests run length texture features between CERR and pyradiomics.
%
% RKP, 03/22/2018

%% Load image
rlmParamFileName = fullfile(fileparts(fileparts(getCERRPath)),...
    'Unit_Testing','tests_for_cerr','test_rlm_radiomics_extraction_settings.json');
cerrFileName = fullfile(fileparts(fileparts(getCERRPath)),...
    'Unit_Testing','data_for_cerr_tests','CERR_plans','head_neck_ex1_20may03.mat.bz2');

planC = loadPlanC(cerrFileName,tempdir);
indexS = planC{end};

paramS = getRadiomicsParamTemplate(rlmParamFileName);
strNum = getMatchingIndex(paramS.structuresC{1},{planC{indexS.structures}.structureName});
scanNum = getStructureAssociatedScan(strNum,planC);

%% Calculate features using CERR

rlmFeat3DdirS = calcGlobalRadiomicsFeatures...
            (scanNum, strNum, paramS, planC);
%firstOrderS = radiomics_first_order_stats(testM(logical(maskBoundingBox3M)), VoxelVol, offsetForEnergy, binwidth);
rlmCombS = rlmFeat3DdirS.Original.rlmFeatS.AvgS;

cerrRlmV = [rlmCombS.gln, rlmCombS.glnNorm, rlmCombS.glv, rlmCombS.hglre, rlmCombS.lglre, rlmCombS.lre, rlmCombS.lrhgle, ...
    rlmCombS.lrlgle, rlmCombS.rln, rlmCombS.rlnNorm, rlmCombS.rlv, rlmCombS.rp, ...
    rlmCombS.sre, rlmCombS.srhgle, rlmCombS.srlgle];


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
% 
% dx = planC{indexS.scan}(scanNum).scanInfo(1).grid1Units;
% dy = planC{indexS.scan}(scanNum).scanInfo(1).grid1Units;
% dz = mode(diff([planC{indexS.scan}(scanNum).scanInfo(:).zValue]));
% pixelSize = [dx dy dz]*10;
% 
% teststruct = PyradWrapper(testM, mask3M, pixelSize, scanType, dirString);
% %teststruct = PyradWrapper(testM, mask3M, scanType);
% 
% pyradRlmNamC = {'GrayLevelNonUniformity', 'GrayLevelNonUniformityNormalized',...
%     'GrayLevelVariance', 'HighGrayLevelRunEmphasis',  'LowGrayLevelRunEmphasis', ...
%     'LongRunEmphasis', 'LongRunHighGrayLevelEmphasis', 'LongRunLowGrayLevelEmphasis',...
%     'RunLengthNonUniformity', 'RunLengthNonUniformityNormalized', 'RunVariance', ...
%     'RunPercentage', 'ShortRunEmphasis','ShortRunHighGrayLevelEmphasis', ...
%     'ShortRunLowGrayLevelEmphasis'};
% 
% pyradRlmNamC = strcat(['original','_glrlm_'],pyradRlmNamC);
% 
% pyRadRlmV = [];
% for i = 1:length(pyradRlmNamC)
%     if isfield(teststruct,pyradRlmNamC{i})
%         pyRadRlmV(i) = teststruct.(pyradRlmNamC{i});
%     else
%         pyRadRlmV(i) = NaN;
%     end
% end
% 
% %% Comparing RLM features of CERR with pyradiomics
% rlmDiffV = (cerrRlmV - pyRadRlmV) ./ cerrRlmV * 100

%% Comparing RLM features of CERR with previously calculated pyradiomics features
saved_pyRadRlmV = [777.569695230386,0.108713486590046,137.196080160637,1838.19890793332,0.0146960037069430,2.35548493733809,4144.12524850824,0.0676383223879843,4597.75943175420,0.641143270951012,0.581048930194830,0.755515738893187,0.827415275589628,1543.60386333568,0.00934658670815600];
rlmDiffV = (cerrRlmV - saved_pyRadRlmV) ./ cerrRlmV * 100
