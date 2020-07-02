function pctDiffS = compareRadiomicsWithPyradWaveletImgNoInterp
% Compare radiomics features between CERR & Pyradiomics on the original image 
%------------------------------------------------------------------------
% AI 07/02/2020

%% Load sample data
fpath = fullfile(fileparts(fileparts(getCERRPath)),...
    'Unit_Testing/data_for_cerr_tests/IBSI1_CT_phantom/IBSILungCancerCTImage.mat.bz2');
planC = loadPlanC(fpath,tempdir);
planC = updatePlanFields(planC);
planC = quality_assure_planC(fpath,planC);
indexS = planC{end};
strName = 'GTV-1';

%% 1. Compute features using Pyradiomics
pyParamFilePath = fullfile(fileparts(fileparts(getCERRPath)),...
            'Unit_Testing/settings_for_comparisons/pyWaveletNoInterp.yaml');
pyFeatS = calcRadiomicsFeatUsingPyradiomics(planC,strName,pyParamFilePath);

%% 2. Compute features using CERR
cerrParamFilePath = fullfile(fileparts(fileparts(getCERRPath)),...
            'Unit_Testing/settings_for_comparisons/cerrWaveletNoInterp.json');
paramS = getRadiomicsParamTemplate(cerrParamFilePath);

strC = {planC{indexS.structures}.structureName};
structNum = getMatchingIndex(paramS.structuresC{1},strC,'exact');
scanNum = getStructureAssociatedScan(structNum,planC);
cerrFeatS = calcGlobalRadiomicsFeatures...
    (scanNum, structNum, paramS, planC);

cerrFieldsC = fieldnames(cerrFeatS);


%% Compare by class

pctDiffS = struct();

% First order
pyFirstOrdFeatS = getPyradFeatDict(pyFeatS,{'wavelet_HHH_firstorder'});
pyFirstOrdFeatS = mapPyradFieldnames(pyFirstOrdFeatS,'wavelet_HHH','firstorder');
%Convert kurtosis to excess kurtosis
pyFirstOrdFeatS.kurtosis = pyFirstOrdFeatS.kurtosis-3;
cerrFirstOrdFeatS = cerrFeatS.(cerrFieldsC{1}).firstOrderS;
diff1S = getPctDiff(cerrFirstOrdFeatS,pyFirstOrdFeatS);
pctDiffS.FirstOrder = diff1S;

% GLCM
pyGlcmFeatS = getPyradFeatDict(pyFeatS,{'wavelet_HHH_glcm'});
pyGlcmFeatS = mapPyradFieldnames(pyGlcmFeatS,'wavelet_HHH','glcm');
cerrGlcmFeatS = cerrFeatS.(cerrFieldsC{1}).glcmFeatS.AvgS;
diff2S = getPctDiff(cerrGlcmFeatS,pyGlcmFeatS);
pctDiffS.GLCM = diff2S;

% GLRLM
pyGlrlmFeatS = getPyradFeatDict(pyFeatS,{'wavelet_HHH_glrlm'});
pyGlrlmFeatS = mapPyradFieldnames(pyGlrlmFeatS,'wavelet_HHH','glrlm');
cerrGlrlmFeatS = cerrFeatS.(cerrFieldsC{1}).rlmFeatS.AvgS;
diff3S = getPctDiff(cerrGlrlmFeatS,pyGlrlmFeatS);
pctDiffS.GLRLM = diff3S;

% NGLDM
pyGldmFeatS = getPyradFeatDict(pyFeatS,{'wavelet_HHH_gldm'});
pyGldmFeatS = mapPyradFieldnames(pyGldmFeatS,'wavelet_HHH','ngldm');
cerrGldmFeatS = cerrFeatS.(cerrFieldsC{1}).ngldmFeatS;
diff4S = getPctDiff(cerrGldmFeatS,pyGldmFeatS);
pctDiffS.NGLDM = diff4S;

% GLSZM
pyGlszmFeatS = getPyradFeatDict(pyFeatS,{'wavelet_HHH_glszm'});
pyGlszmFeatS = mapPyradFieldnames(pyGlszmFeatS,'wavelet_HHH','glszm');
cerrGlszmFeatS = cerrFeatS.(cerrFieldsC{1}).szmFeatS;
diff5S = getPctDiff(cerrGlszmFeatS,pyGlszmFeatS);
pctDiffS.GLSZM = diff5S;

%% -------- Get pct diff -------------
    function outS = getPctDiff(feat1S,feat2S)
        
        outS = struct();
        featC = fieldnames(feat1S);
        for n = 1:length(featC)
            val1 = feat1S.(featC{n});
            if isfield(feat2S,featC{n})
                val2 = feat2S.(featC{n});
                pctDiff =(val1-val2)*100/val2;
                outS.(featC{n})= pctDiff;
            end
        end
        
    end

end