% this script tests NGLDM features between CERR and pyradiomics.
%
% RKP, 03/22/2018

%% load image
gldmParamFileName = fullfile(fileparts(fileparts(getCERRPath)),...
    'Unit_Testing','tests_for_cerr','test_ngldm_radiomics_extraction_settings.json');
cerrFileName = fullfile(fileparts(fileparts(getCERRPath)),...
    'Unit_Testing','data_for_cerr_tests','CERR_plans','head_neck_ex1_20may03.mat.bz2');

planC = loadPlanC(cerrFileName,tempdir);
indexS = planC{end};

paramS = getRadiomicsParamTemplate(gldmParamFileName);
strNum = getMatchingIndex(paramS.structuresC{1},{planC{indexS.structures}.structureName});
scanNum = getStructureAssociatedScan(strNum,planC);

%% NGLDM features CERR

ngldmS = calcGlobalRadiomicsFeatures...
            (scanNum, strNum, paramS, planC);
ngldmS = ngldmS.Original.ngldmFeatS;

cerrNgldmV = [ngldmS.lde, ngldmS.hde, ngldmS.lgce, ngldmS.hgce, ...
    ngldmS.ldlge, ngldmS.ldhge, ngldmS.hdlge, ngldmS.hdhge, ...
    ngldmS.gln, ngldmS.glnNorm, ngldmS.dcn, ngldmS.dcnNorm,...
    ngldmS.dcp, ngldmS.glv, ngldmS.dcv, ngldmS.entropy, ngldmS.energy];

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
% 
% %teststruct = PyradWrapper(testM, mask3M, scanType);
% 
% pyradNgldmNamC = {'SmallDependenceEmphasis', 'LargeDependenceEmphasis',...
%     'LowGrayLevelCountEmphasis', 'HighGrayLevelCountEmphasis',  'SmallDependenceLowGrayLevelEmphasis', ...
%     'SmallDependenceHighGrayLevelEmphasis', 'LargeDependenceLowGrayLevelEmphasis', ...
%     'LargeDependenceHighGrayLevelEmphasis', 'GrayLevelNonUniformity', 'GrayLevelNonUniformityNorm', ...
%     'DependenceNonUniformity', 'DependenceNonUniformityNormalized', ...
%     'DependencePercentage', 'GrayLevelVariance', 'DependenceVariance', ...
%     'DependenceEntropy', 'DependenceEnergy'};
% 
% 
% pyradNgldmNamC = strcat(['original', '_gldm_'],pyradNgldmNamC);
% 
% pyRadNgldmV = [];
% for i = 1:length(pyradNgldmNamC)
%     if isfield(teststruct,pyradNgldmNamC{i})
%         pyRadNgldmV(i) = teststruct.(pyradNgldmNamC{i});
%     else
%         pyRadNgldmV(i) = NaN;
%     end
% end
% 
% %% Compare
% ngldmDiffV = (cerrNgldmV - pyRadNgldmV) ./ cerrNgldmV * 100

%% Compare with previously calculated pyradiomics features
saved_pyRadNgldmV = [0.177896163786327,80.7514028586554,NaN,NaN,0.00117423243903225,380.447741305586,3.84549682517831,136232.842773954,1250.78930651138,NaN,634.668395976707,0.0671962303839817,NaN,122.726429080550,26.6319748251348,7.44897904303236,NaN];
ngldmDiffV = (cerrNgldmV - saved_pyRadNgldmV) ./ cerrNgldmV * 100