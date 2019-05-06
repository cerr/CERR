% this script tests shape features between CERR and pyradiomics.
%
% RKP, 03/22/2018

%% load image
shapeParamFileName = fullfile(fileparts(fileparts(getCERRPath)),...
    'Unit_Testing','tests_for_cerr','test_shape_radiomics_extraction_settings.json');
cerrFileName = fullfile(fileparts(fileparts(getCERRPath)),...
    'Unit_Testing','data_for_cerr_tests','CERR_plans','head_neck_ex1_20may03.mat.bz2');

planC = loadPlanC(cerrFileName,tempdir);
indexS = planC{end};

paramS = getRadiomicsParamTemplate(shapeParamFileName);
strNum = getMatchingIndex(paramS.structuresC{1},{planC{indexS.structures}.structureName});
scanNum = getStructureAssociatedScan(strNum,planC);

%% Calculate features using CERR

shapeM = calcGlobalRadiomicsFeatures...
            (scanNum, strNum, paramS, planC);


%% CERR Shape features


shapeS = shapeM.Original.shapeS;

cerrShapeV = [shapeS.majorAxis, shapeS.minorAxis, shapeS.leastAxis, ...
    shapeS.flatness, shapeS.elongation, shapeS.max3dDiameter, shapeS.max2dDiameterAxialPlane,...
    shapeS.max2dDiameterSagittalPlane', shapeS.max2dDiameterCoronalPlane, ...
    shapeS.Compactness1, shapeS.Compactness2, shapeS.spherDisprop, ...
    shapeS.sphericity, shapeS.surfToVolRatio/10,...
    shapeS.surfArea*100, shapeS.volume*1000];


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
% pyradShapeNamC = {'MajorAxis', 'MinorAxis', 'LeastAxis', 'Flatness',  'Elongation', ...
%     'Maximum3DDiameter', 'Maximum2DDiameterSlice', 'Maximum2DDiameterRow', ...
%     'Maximum2DDiameterColumn', 'Compactness1','Compactness2','spherDisprop','Sphericity', ...
%     'SurfaceVolumeRatio','SurfaceArea','Volume'};
% pyradShapeNamC = strcat(['original','_shape_'],pyradShapeNamC);
% pyRadShapeV = [];
% for i = 1:length(pyradShapeNamC)
%     if isfield(teststruct,pyradShapeNamC{i})
%         pyRadShapeV(i) = teststruct.(pyradShapeNamC{i});
%     else
%         pyRadShapeV(i) = NaN;
%     end
% end
% 
% %% Comparing shape params of CERR with pyradiomics
% shapeDiffV = (cerrShapeV - pyRadShapeV) ./ cerrShapeV * 100

%% Comparing shape params of CERR with previously calculated pyradiomics params
saved_pyRadShapeV = [NaN,NaN,NaN,0.415267128605966,0.540286983388590,101.867561078098,68.3520299625402,90.3382532485547,96.2548700066651,NaN,NaN,NaN,0.597426000396528,0.167523770503953,18899.3616931740,NaN];
shapeDiffV = (cerrShapeV - saved_pyRadShapeV) ./ cerrShapeV * 100