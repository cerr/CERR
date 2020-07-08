function [cerrFeatS,pyFeatS] = compareRadiomicsWithPyradOriginalImgNoInterp
% Compare radiomics features between CERR & Pyradiomics on the original image 
%------------------------------------------------------------------------
% AI 07/01/2020

%% Load sample data
fpath = fullfile(fileparts(fileparts(getCERRPath)),...
    'Unit_Testing/data_for_cerr_tests/IBSI1_CT_phantom/IBSILungCancerCTImage.mat.bz2');
planC = loadPlanC(fpath,tempdir);
planC = updatePlanFields(planC);
planC = quality_assure_planC(fpath,planC);
indexS = planC{end};
strName = 'GTV-1';

%% 1. Compute features using CERR
cerrParamFilePath = fullfile(fileparts(fileparts(getCERRPath)),...
            'Unit_Testing/settings_for_comparisons/cerrOrigNoInterp.json');
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
            'Unit_Testing/settings_for_comparisons/pyOrigNoInterp.yaml');
pyCalcS = calcRadiomicsFeatUsingPyradiomics(planC,strName,pyParamFilePath);


%Map to cerr fieldnames
pyFeatS = struct();

% First-order
pyFirstOrdFeatS = getPyradFeatDict(pyCalcS,{['original','_firstorder']});
pyFirstOrdFeatS = mapPyradFieldnames(pyFirstOrdFeatS,'original','firstorder');
pyFeatS.(filtName).firstOrderS = pyFirstOrdFeatS;

% GLCM
pyGlcmFeatS = getPyradFeatDict(pyCalcS,{['original','_glcm']});
pyGlcmFeatS = mapPyradFieldnames(pyGlcmFeatS,'original','glcm');
pyFeatS.(filtName).glcmFeatS = pyGlcmFeatS;

% GLRLM
pyGlrlmFeatS = getPyradFeatDict(pyCalcS,{['original','_glrlm']});
pyGlrlmFeatS = mapPyradFieldnames(pyGlrlmFeatS,'original','glrlm');
pyFeatS.(filtName).rlmFeatS = pyGlrlmFeatS;

% NGLDM
pyGldmFeatS = getPyradFeatDict(pyCalcS,{['original','_gldm']});
pyGldmFeatS = mapPyradFieldnames(pyGldmFeatS,'original','ngldm');
pyFeatS.(filtName).ngldmFeatS = pyGldmFeatS;

%GLSZM
pyGlszmFeatS = getPyradFeatDict(pyCalcS,{['original','_glszm']});
pyGlszmFeatS = mapPyradFieldnames(pyGlszmFeatS,'original','glszm');
pyFeatS.(filtName).szmFeatS = pyGlszmFeatS;


end