function [cerrFeatS,pyFeatS,diffS,pctDiffS] = ...
    compareCerrWithPyradAllFeatures(planC,...
    strName,cerrParamFile,pyradParamFile,pyradPath)
% Compute features using settings for CERR & Pyradiomics, map feature
% names, and return % differences in values.
% % diff is computed as: (cerrVal - pyradVal)*100/pyRadval
% ----------------------------------------------------------------------
% fpath         : Path to CERR archive
% strName       : Structure index (numeric) or structure name (string)
% cerrParamFile : path to settings file for CERR (.json)
% paramFile     : Path to settings file for Pyradiomics (.yaml)
% pyradPath     : Path to Python pkgs including Pyradiomics & Scipy
%               : Typically, 'C:\Miniconda3\lib\site-packages'
%----------------------------------------------------------------------
% AI 09/14/2023

%Load sample data
if ischar(fpath)
    fpath = planC;
    planC = loadPlanC(fpath,tempdir);
    planC = updatePlanFields(planC);
    planC = quality_assure_planC(fpath,planC);
end

%% Compare features derived from resamples images using CERR & Pyradiomics
[cerrFeatS,pyFeatS] = compareCerrWithPyrad(cerrParamFile,...
                     pyradParamFile,pyradPath,strName,...
                     'original','all',...
                     planC);

%% Compare features
classesC = {'firstorder','glcmAvg','glrlmAvg','ngldmAvg','glszmAvg'};
%pyFeatS = getPyradFeatDict(pyFeatS,{'original_firstorder',...
%    'original_glcm','original_glrlm','original_gldm','original_glszm'});


for nclass = 1:length(classesC)

    %Map pyrad features to CERR features
    switch(classesC{nclass})
        case 'firstorder'
            pyClassFeatS = getPyradFeatDict(pyFeatS,{'original_firstorder'});
            pyClassFeatS = mapPyradFieldnames(pyClassFeatS,'original',...
                'firstorder');
            %Convert kurtosis to excess kurtosis
            pyClassFeatS.kurtosis = pyClassFeatS.kurtosis -3;

            cerrClassFeatS = cerrFeatS.firstOrderS;

        case 'glcmAvg'
            pyClassFeatS = getPyradFeatDict(pyFeatS,{'original_glcm'});
            pyClassFeatS = mapPyradFieldnames(pyClassFeatS,'original',...
                'glcm');
            cerrClassFeatS = cerrFeatS.glcmFeatS.AvgS;

        case 'glrlmAvg'
            pyClassFeatS = getPyradFeatDict(pyFeatS,{'original_glrlm'});
            pyClassFeatS = mapPyradFieldnames(pyClassFeatS,'original',...
                'glrlm');
            cerrClassFeatS = cerrFeatS.rlmFeatS.AvgS;

        case 'ngldmAvg'
            pyClassFeatS = getPyradFeatDict(pyFeatS,{'original_gldm'});
            pyClassFeatS = mapPyradFieldnames(pyClassFeatS,'original',...
                'ngldm');
            cerrClassFeatS = cerrFeatS.ngldmFeatS;

        case 'glszmAvg'
            pyClassFeatS = getPyradFeatDict(pyFeatS,{'original_glszm'});
            pyClassFeatS = mapPyradFieldnames(pyClassFeatS,'original',...
                'glszm');
            cerrClassFeatS = cerrFeatS.szmFeatS;
    end

    cerrClassFeatListC = fieldnames(cerrClassFeatS);
    [classDiffS,classPctS] = calcPctDiff(cerrClassFeatS,...
        pyClassFeatS,cerrClassFeatListC);
    diffS.(classesC{nclass}) = classDiffS;
    pctDiffS.(classesC{nclass}) = classPctS;

end

 %%------ Support functions----

    function [diffS,pctDiffS] = calcPctDiff(cerrFeatClassS,pyFeatClassS,featC)

        diffS = struct();
        pctDiffS = struct();
        for nFeat = 1:length(featC)
            cerrVal = cerrFeatClassS.(featC{nFeat});
            if isfield(pyFeatClassS,featC{nFeat})
                pyRadVal = pyFeatClassS.(featC{nFeat});
                diffVal = cerrVal-pyRadVal;
                pctDiff = diffVal*100/pyRadVal;
                diffS.(featC{nFeat}) = diffVal;
                pctDiffS.(featC{nFeat}) = pctDiff;
            end
        end
    end

end