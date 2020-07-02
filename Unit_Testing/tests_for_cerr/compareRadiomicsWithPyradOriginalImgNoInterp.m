function diffS = compareRadiomicsWithPyradOriginalImgNoInterp
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

%% 1. Compute features using Pyradiomics
pyParamFilePath = fullfile(fileparts(fileparts(getCERRPath)),...
            'Unit_Testing/settings_for_comparisons/pyOrigNoInterp.yaml');
pyFeatS = calcRadiomicsFeatUsingPyradiomics(planC,strName,pyParamFilePath);

%% 2. Compute features using CERR
cerrParamFilePath = fullfile(fileparts(fileparts(getCERRPath)),...
            'Unit_Testing/settings_for_comparisons/cerrOrigNoInterp.json');
paramS = getRadiomicsParamTemplate(cerrParamFilePath);

strC = {planC{indexS.structures}.structureName};
structNum = getMatchingIndex(paramS.structuresC{1},strC,'exact');
scanNum = getStructureAssociatedScan(structNum,planC);
cerrFeatS = calcGlobalRadiomicsFeatures...
    (scanNum, structNum, paramS, planC);

cerrFieldsC = fieldnames(cerrFeatS);


%% Compare by class

diffS = struct();

% First order
pyFirstOrdFeatS = getPyradFeatDict(pyFeatS,{'original_firstorder'});
pyFirstOrdFeatS = mapPyradFieldnames(pyFirstOrdFeatS,'original','firstorder');
%Convert kurtosis to excess kurtosis
pyFirstOrdFeatS.kurtosis = pyFirstOrdFeatS.kurtosis-3;
cerrFirstOrdFeatS = cerrFeatS.(cerrFieldsC{1}).firstOrderS;
diff1S = getPctDiff(cerrFirstOrdFeatS,pyFirstOrdFeatS);
diffS.fFirstOrder = diff1S;

% GLCM
pyGlcmFeatS = getPyradFeatDict(pyFeatS,{'original_glcm'});
pyGlcmFeatS = mapPyradFieldnames(pyGlcmFeatS,'original','glcm');
cerrGlcmFeatS = cerrFeatS.(cerrFieldsC{1}).glcmFeatS.AvgS;
diff2S = getPctDiff(cerrGlcmFeatS,pyGlcmFeatS);
diffS.GLCM = diff2S;

% GLRLM
pyGlrlmFeatS = getPyradFeatDict(pyFeatS,{'original_glrlm'});
pyGlrlmFeatS = mapPyradFieldnames(pyGlrlmFeatS,'original','glrlm');
cerrGlrlmFeatS = cerrFeatS.(cerrFieldsC{1}).rlmFeatS.AvgS;
diff3S = getPctDiff(cerrGlrlmFeatS,pyGlrlmFeatS);
diffS.GLRLM = diff3S;

% NGLDM
pyGldmFeatS = getPyradFeatDict(pyFeatS,{'original_gldm'});
pyGldmFeatS = mapPyradFieldnames(pyGldmFeatS,'original','ngldm');
cerrGldmFeatS = cerrFeatS.(cerrFieldsC{1}).ngldmFeatS;
diff4S = getPctDiff(cerrGldmFeatS,pyGldmFeatS);
diffS.NGLDM = diff4S;

% GLSZM
pyGlszmFeatS = getPyradFeatDict(pyFeatS,{'original_glszm'});
pyGlszmFeatS = mapPyradFieldnames(pyGlszmFeatS,'original','glszm');
cerrGlszmFeatS = cerrFeatS.(cerrFieldsC{1}).szmFeatS;
diff5S = getPctDiff(cerrGlszmFeatS,pyGlszmFeatS);
diffS.GLSZM = diff5S;

%% -------- Get pct diff -------------
    function pctDiffS = getPctDiff(feat1S,feat2S)
        
        pctDiffS = struct();
        featC = fieldnames(feat1S);
        for n = 1:length(featC)
            val1 = feat1S.(featC{n});
            if isfield(feat2S,featC{n})
                val2 = feat2S.(featC{n});
                pctDiff =(val1-val2)*100/val2;
                pctDiffS.(featC{n})= pctDiff;
            end
        end
        
    end

end