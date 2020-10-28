function diffS = comparePyradWithIBSIOrigImgWithInterp
% Compare pyradiomics features against IBSI benchmark for config C. 
%--------------------------------------------------------------------------
% AI 7/1/2020

%% Calc. features for configuration 'C' using Pyradiomics
fpath = fullfile(fileparts(fileparts(getCERRPath)),...
    'Unit_Testing/data_for_cerr_tests/IBSI1_CT_phantom/IBSILungCancerCTImage.mat.bz2');
planC = loadPlanC(fpath,tempdir);
planC = updatePlanFields(planC);
planC = quality_assure_planC(fpath,planC);
strName='GTV-1';

configPath_avg = fullfile(fileparts(fileparts(getCERRPath)),...
    'Unit_Testing/settings_for_comparisons/pyRadConfigC_avg.yaml');
pyFeat1S = calcRadiomicsFeatUsingPyradiomics(planC,strName,configPath_avg);
configPath_merge = fullfile(fileparts(fileparts(getCERRPath)),...
    'Unit_Testing/settings_for_comparisons/pyRadConfigC_merge.yaml');
pyFeat2S = calcRadiomicsFeatUsingPyradiomics(planC,strName,configPath_merge);

%% Compare with IBSI

% Get IBSI bechmark
ibsiConfigCResult = fullfile(fileparts(fileparts(getCERRPath)),...
    'Unit_Testing/data_for_cerr_tests/IBSI1_CT_phantom/IBSI_results_configC.mat');
temp = load(ibsiConfigCResult);
IBSIfeatS = temp.IBSIfeatS;

% Shape features
pyShapeS = getPyradFeatDict(pyFeat1S,{'original_shape'});
pyShapeS = mapPyradFieldnames(pyShapeS,'original','shape');
shapeFeatC = fieldnames(IBSIfeatS.shapeS);
for n = 1:length(shapeFeatC)
    ibsiVal = IBSIfeatS.shapeS.(shapeFeatC{n});
    if isfield(pyShapeS,shapeFeatC{n})
        pyRadVal = pyShapeS.(shapeFeatC{n});
        pctDiff = (pyRadVal-ibsiVal)*100/ibsiVal;
        diffS.Shape.(shapeFeatC{n}) = pctDiff;
    end
end

% First order features
pyFirstOrdS = getPyradFeatDict(pyFeat1S,{'original_firstorder'});
pyFirstOrdS = mapPyradFieldnames(pyFirstOrdS,'original','firstorder');
%Convert kurtosis to excess kurtosis
pyFirstOrdS.kurtosis = pyFirstOrdS.kurtosis -3;
firstOrdFeatC = fieldnames(IBSIfeatS.Original.firstOrderS);
for n = 1:length(firstOrdFeatC)
    ibsiVal = IBSIfeatS.Original.firstOrderS.(firstOrdFeatC{n});
    if isfield(pyFirstOrdS,firstOrdFeatC{n})
        pyRadVal = pyFirstOrdS.(firstOrdFeatC{n});
        pctDiff = (pyRadVal-ibsiVal)*100/ibsiVal;
        diffS.FirstOrder.(firstOrdFeatC{n}) = pctDiff;
    end
end


% GLCM
%Avg
pyGlcmS = getPyradFeatDict(pyFeat1S,{'original_glcm'});
pyGlcmS = mapPyradFieldnames(pyGlcmS,'original','glcm');
glcmFeatC = fieldnames(IBSIfeatS.Original.glcmFeatS.AvgS);
for n = 1:length(glcmFeatC)
    ibsiVal = IBSIfeatS.Original.glcmFeatS.AvgS.(glcmFeatC{n});
    if isfield(pyGlcmS,glcmFeatC{n})
        pyRadVal = pyGlcmS.(glcmFeatC{n});
        pctDiff = (pyRadVal-ibsiVal)*100/ibsiVal;
        diffS.GLCM.Avg.(glcmFeatC{n}) = pctDiff;
    end
end
%Merge
pyGlcm2S = getPyradFeatDict(pyFeat2S,{'original_glcm'});
pyGlcm2S = mapPyradFieldnames(pyGlcm2S,'original','glcm');
glcmFeat2C = fieldnames(IBSIfeatS.Original.glcmFeatS.CombS);
for n = 1:length(glcmFeat2C)
    ibsiVal = IBSIfeatS.Original.glcmFeatS.CombS.(glcmFeat2C{n});
    if isfield(pyGlcm2S,glcmFeat2C{n})
        pyRadVal = pyGlcm2S.(glcmFeat2C{n});
        pctDiff = (pyRadVal-ibsiVal)*100/ibsiVal;
        diffS.GLCM.Merge.(glcmFeat2C{n}) = pctDiff;
    end
end

% GLRLM
%Avg
pyGlrlmS = getPyradFeatDict(pyFeat1S,{'original_glrlm'});
pyGlrlmS = mapPyradFieldnames(pyGlrlmS,'original','glrlm');
glrlmFeatC = fieldnames(IBSIfeatS.Original.rlmFeatS.AvgS);
for n = 1:length(glrlmFeatC)
    ibsiVal = IBSIfeatS.Original.rlmFeatS.AvgS.(glrlmFeatC{n});
    if isfield(pyGlrlmS,glrlmFeatC{n})
        pyRadVal = pyGlrlmS.(glrlmFeatC{n});
        pctDiff = (pyRadVal-ibsiVal)*100/ibsiVal;
        diffS.GLRLM.Avg.(glrlmFeatC{n}) = pctDiff;
    end
end
%Merge
pyGlrlm2S = getPyradFeatDict(pyFeat2S,{'original_glrlm'});
pyGlrlm2S = mapPyradFieldnames(pyGlrlm2S,'original','glrlm');
glrlm2FeatC = fieldnames(IBSIfeatS.Original.rlmFeatS.CombS);
for n = 1:length(glrlm2FeatC)
    ibsiVal = IBSIfeatS.Original.rlmFeatS.CombS.(glrlm2FeatC{n});
    if isfield(pyGlrlm2S,glrlm2FeatC{n})
        pyRadVal = pyGlrlm2S.(glrlm2FeatC{n});
        pctDiff = (pyRadVal-ibsiVal)*100/ibsiVal;
        diffS.GLRLM.Merge.(glrlm2FeatC{n}) = pctDiff;
    end
end

% NGTDM
pyNgtdmS = getPyradFeatDict(pyFeat1S,{'original_ngtdm'});
pyNgtdmS = mapPyradFieldnames(pyNgtdmS,'original','ngtdm');
ngtdmFeatC = fieldnames(IBSIfeatS.Original.ngtdmFeatS);
for n = 1:length(ngtdmFeatC)
    ibsiVal = IBSIfeatS.Original.ngtdmFeatS.(ngtdmFeatC{n});
    if isfield(pyNgtdmS,ngtdmFeatC{n})
        pyRadVal = pyNgtdmS.(ngtdmFeatC{n});
        pctDiff = (pyRadVal-ibsiVal)*100/ibsiVal;
        diffS.NGTDM.(ngtdmFeatC{n}) = pctDiff;
    end
end

% SZM features
pyGlszmS = getPyradFeatDict(pyFeat1S,{'original_glszm'});
pyGlszmS = mapPyradFieldnames(pyGlszmS,'original','glszm');
glszmFeatC = fieldnames(IBSIfeatS.Original.szmFeatS);
for n = 1:length(glszmFeatC)
    ibsiVal = IBSIfeatS.Original.szmFeatS.(glszmFeatC{n});
    if isfield(pyGlszmS,glszmFeatC{n})
        pyRadVal = pyGlszmS.(glszmFeatC{n});
        pctDiff = (pyRadVal-ibsiVal)*100/ibsiVal;
        diffS.GLSZM.(glszmFeatC{n}) = pctDiff;
    end
end

end
