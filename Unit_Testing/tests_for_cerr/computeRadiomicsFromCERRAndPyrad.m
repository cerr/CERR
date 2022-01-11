function [cerrFeatS,pyFeatS] = computeRadiomicsFromCERRAndPyrad(planC,structNum,...
    cerrParamFilePath,pyParamFilePath)
%
% function [cerrFeatS,pyFeatS] = computeRadiomicsFromCERRAndPyrad(planC,structNum,...
%     cerrParamFilePath,pyParamFilePath)
%
% This function returns radiomics features from CERR and PyRadiomics.  
% planC: CERR's planC data structure.
% structNum: Structure index in planC to compute radiomics.
% cerrParamFilePath: Radiomics settings for CERR.
% pyParamFilePath: Radiomics settings for PyRadiomics.
%
% This routine assumes that PyRadiomics and SciPy are already added to Python path.
% For example, on Windows OS
% P = py.sys.path;
% insert(P,int64(0),'C:\Program Files\Python37\Lib\site-packages\radiomics');
% P = py.sys.path;
% insert(P,int64(0),'C:\Program Files\Python37\Lib\site-packages\scipy');


%------------------------------------------------------------------------
% APA 01/08/2022

%% 1. Compute features using CERR
% cerrParamFilePath = fullfile(fileparts(fileparts(getCERRPath)),...
%             'Unit_Testing/settings_for_comparisons/cerrOrigNoInterp.json');
paramS = getRadiomicsParamTemplate(cerrParamFilePath);

% strC = {planC{indexS.structures}.structureName};
% structNum = getMatchingIndex(paramS.structuresC{1},strC,'exact');
scanNum = getStructureAssociatedScan(structNum,planC);
cerrFeatS = calcGlobalRadiomicsFeatures...
    (scanNum, structNum, paramS, planC);

filtName = 'Original';

%% 2. Compute features using Pyradiomics
% pyParamFilePath = fullfile(fileparts(fileparts(getCERRPath)),...
%             'Unit_Testing/settings_for_comparisons/pyOrigNoInterp.yaml');
% pyParamFilePath = 'L:\Aditya\forJung\TCIA_Jung\features_1_6_2022\pyOrigWithInterp.yaml';
pyCalcS = calcRadiomicsFeatUsingPyradiomics(planC,structNum,pyParamFilePath);


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