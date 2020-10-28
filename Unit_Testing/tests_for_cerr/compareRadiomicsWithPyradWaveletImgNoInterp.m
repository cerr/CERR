function [cerrFeatS,pyFeatS] = compareRadiomicsWithPyradWaveletImgNoInterp
% Compare radiomics features between CERR & Pyradiomics on wavelet images
%--------------------------------------------------------------------------
% AI 07/02/2020

%% Load sample data
fpath = fullfile(fileparts(fileparts(getCERRPath)),...
    'Unit_Testing/data_for_cerr_tests/IBSI1_CT_phantom/IBSILungCancerCTImage.mat.bz2');
planC = loadPlanC(fpath,tempdir);
planC = updatePlanFields(planC);
planC = quality_assure_planC(fpath,planC);
indexS = planC{end};
strName = 'GTV-1';
decomStr = 'HHH';

%% 1. Compute features using CERR
cerrParamFilePath = fullfile(fileparts(fileparts(getCERRPath)),...
    'Unit_Testing/settings_for_comparisons/cerrWaveletNoInterp.json');
paramS = getRadiomicsParamTemplate(cerrParamFilePath);

strC = {planC{indexS.structures}.structureName};
structNum = getMatchingIndex(paramS.structuresC{1},strC,'exact');
scanNum = getStructureAssociatedScan(structNum,planC);
cerrFeatS = calcGlobalRadiomicsFeatures...
    (scanNum, structNum, paramS, planC);
filtName = fieldnames(cerrFeatS);
filtName = filtName{1};

%% 2. Compute features using Pyradiomics
pyParamFilePath = fullfile(fileparts(fileparts(getCERRPath)),...
    'Unit_Testing/settings_for_comparisons/pyWaveletNoInterp.yaml');
pyCalcS = calcRadiomicsFeatUsingPyradiomics(planC,strName,pyParamFilePath);

%Map to cerr fieldnames
pyFeatS = struct();

% First-order
pyFirstOrdFeatS = getPyradFeatDict(pyCalcS,{['wavelet_',decomStr,'_firstorder']});
pyFirstOrdFeatS = mapPyradFieldnames(pyFirstOrdFeatS,['wavelet_',decomStr],'firstorder');
pyFeatS.(filtName).firstOrderS = pyFirstOrdFeatS;

% GLCM
pyGlcmFeatS = getPyradFeatDict(pyCalcS,{['wavelet_',decomStr,'_glcm']});
pyGlcmFeatS = mapPyradFieldnames(pyGlcmFeatS,['wavelet_',decomStr],'glcm');
pyFeatS.(filtName).glcmFeatS = pyGlcmFeatS;

% GLRLM
pyGlrlmFeatS = getPyradFeatDict(pyCalcS,{['wavelet_',decomStr,'_glrlm']});
pyGlrlmFeatS = mapPyradFieldnames(pyGlrlmFeatS,['wavelet_',decomStr],'glrlm');
pyFeatS.(filtName).rlmFeatS = pyGlrlmFeatS;

% NGLDM
pyGldmFeatS = getPyradFeatDict(pyCalcS,{['wavelet_',decomStr,'_gldm']});
pyGldmFeatS = mapPyradFieldnames(pyGldmFeatS,['wavelet_',decomStr],'ngldm');
pyFeatS.(filtName).ngldmFeatS = pyGldmFeatS;

%GLSZM
pyGlszmFeatS = getPyradFeatDict(pyCalcS,{['wavelet_',decomStr,'_glszm']});
pyGlszmFeatS = mapPyradFieldnames(pyGlszmFeatS,['wavelet_',decomStr],'glszm');
pyFeatS.(filtName).szmFeatS = pyGlszmFeatS;

end