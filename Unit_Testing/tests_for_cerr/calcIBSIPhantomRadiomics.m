function cerrFeatS = calcIBSIPhantomRadiomics(config)
% Compute features using IBSI reference Lung CT image and configurations.
%--------------------------------------------------------------------------
% INPUTS
% config : 'C' or 'A' (to use settings corresponding to IBSI coonfig C or A).
%--------------------------------------------------------------------------
% AI 06/25/2020


%% Get config file path
switch(config)
    
    case 'C'
        configPath_avg = fullfile(fileparts(fileparts(getCERRPath)),...
            'Unit_Testing/settings_for_comparisons/IBSIconfigC_avg.json');
        configPath_merge = fullfile(fileparts(fileparts(getCERRPath)),...
            'Unit_Testing/settings_for_comparisons/IBSIconfigC_merge.json');
      
    case 'A'
        configPath_avg = fullfile(fileparts(fileparts(getCERRPath)),...
            'Unit_Testing/settings_for_comparisons/IBSIconfigA_avg.json');
        configPath_merge = fullfile(fileparts(fileparts(getCERRPath)),...
            'Unit_Testing/settings_for_comparisons/IBSIconfigA_merge.json');
        
end

%% Load IBSI CT phantom
fpath = fullfile(fileparts(fileparts(getCERRPath)),...
    'Unit_Testing/data_for_cerr_tests/IBSI1_CT_phantom/IBSILungCancerCTImage.mat.bz2');
planC = loadPlanC(fpath,tempdir);
planC = updatePlanFields(planC);
planC = quality_assure_planC(fpath,planC);
indexS = planC{end};

%% Compute features using CERR
%Read config files
param1S = getRadiomicsParamTemplate(configPath_avg);
param2S = getRadiomicsParamTemplate(configPath_merge);

%Get struct name
strName = param1S.structuresC;
strName = strName{1};
strC = {planC{indexS.structures}.structureName};
structNum = getMatchingIndex(strName,strC,'exact');
scanNum = getStructureAssociatedScan(structNum,planC);

%Compute features (avg)
cerrFeatS = calcGlobalRadiomicsFeatures...
    (scanNum, structNum, param1S, planC);

%Compute features (merge)
cerrFeat2S = calcGlobalRadiomicsFeatures...
    (scanNum, structNum, param2S, planC);
mergeFieldsC = intersect(fieldnames(cerrFeatS),fieldnames(cerrFeat2S));

for m = 1:length(mergeFieldsC)
    mergeFeatC = intersect( fieldnames(cerrFeatS.(mergeFieldsC{m})),...
        fieldnames(cerrFeat2S.(mergeFieldsC{m})));
    for n = 1:length(mergeFeatC)
        addFieldC = fieldnames(cerrFeat2S.(mergeFieldsC{m}).(mergeFeatC{n}));
        cerrFeatS.(mergeFieldsC{m}).(mergeFeatC{n}).(addFieldC{1}) ...
            = cerrFeat2S.(mergeFieldsC{m}).(mergeFeatC{n}).(addFieldC{1});
    end
end


end