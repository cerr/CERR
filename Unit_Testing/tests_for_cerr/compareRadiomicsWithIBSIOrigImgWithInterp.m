function [cerrFeatS,IBSIfeatS,pctDiffS] = compareRadiomicsWithIBSIOrigImgWithInterp
% Function to compare radiomics features computed using CERR against
% the IBSI benchmark for configuration C.

%% 1. Calc. features for configuration 'C' using CERR
cerrFeatS = calcIBSIPhantomRadiomics('C');

%% Get IBSI benchmarks
ibsiConfigCResult = fullfile(fileparts(fileparts(getCERRPath)),...
            'Unit_Testing/data_for_cerr_tests/IBSI1_CT_phantom/IBSI_results_configC.mat');
temp = load(ibsiConfigCResult);
IBSIfeatS = temp.IBSIfeatS;

%% Compare results for each feature class
pctDiffS = struct();
%Shape features
shapeFeatC = fieldnames(IBSIfeatS.shapeS);
for n = 1:length(shapeFeatC)
    ibsiVal = IBSIfeatS.shapeS.(shapeFeatC{n});
    cerrVal = cerrFeatS.shapeS.(shapeFeatC{n});
    if ismember(shapeFeatC{n},{'volume','filledVolume'})
        cerrVal = cerrVal*1000; %cm^3 to mm^3
    elseif strcmp(shapeFeatC{n},'surfArea')
        cerrVal = cerrVal*100; %cm^2 to mm^2
    elseif ismember(shapeFeatC{n},{'majorAxis','minorAxis','leastAxis'}) || ...
            contains(shapeFeatC{n},'Diameter')
         cerrVal = cerrVal*10; %cm to mm
    elseif strcmp(shapeFeatC{n},'surfToVolRatio')
        cerrVal = cerrVal/10; %cm^-1 to mm^-1
    end
    pctDiff =(cerrVal-ibsiVal)*100/ibsiVal;
    pctDiffS.Shape.(shapeFeatC{n}) = pctDiff;
end

%IVH features
IVHfeatC = fieldnames(IBSIfeatS.Original.ivhFeaturesS);
for n = 1:length(IVHfeatC)
    ibsiVal = IBSIfeatS.Original.ivhFeaturesS.(IVHfeatC{n});
    cerrVal = cerrFeatS.Original.ivhFeaturesS.(IVHfeatC{n});
    pctDiff =(cerrVal-ibsiVal)*100/ibsiVal;
    pctDiffS.IVH.(IVHfeatC{n}) = pctDiff;
end

%First-order intensity features
firstOrdFeatC = fieldnames(IBSIfeatS.Original.firstOrderS);
for n = 1:length(firstOrdFeatC)
    ibsiVal = IBSIfeatS.Original.firstOrderS.(firstOrdFeatC{n});
    cerrVal = cerrFeatS.Original.firstOrderS.(firstOrdFeatC{n});
    pctDiff =(cerrVal-ibsiVal)*100/ibsiVal;
    pctDiffS.FirstOrder.(firstOrdFeatC{n}) = pctDiff;
end

%GLCM features
%Avg
glcmFeatC = fieldnames(IBSIfeatS.Original.glcmFeatS.AvgS);
for n = 1:length(glcmFeatC)
    ibsiVal = IBSIfeatS.Original.glcmFeatS.AvgS.(glcmFeatC{n});
    cerrVal = cerrFeatS.Original.glcmFeatS.AvgS.(glcmFeatC{n});
    pctDiff =(cerrVal-ibsiVal)*100/ibsiVal;
    pctDiffS.GLCM.Avg.(glcmFeatC{n}) = pctDiff;
end
%Merge
glcmFeatC = fieldnames(IBSIfeatS.Original.glcmFeatS.AvgS);
for n = 1:length(glcmFeatC)
    ibsiVal = IBSIfeatS.Original.glcmFeatS.AvgS.(glcmFeatC{n});
    cerrVal = cerrFeatS.Original.glcmFeatS.AvgS.(glcmFeatC{n});
    pctDiff =(cerrVal-ibsiVal)*100/ibsiVal;
    pctDiffS.GLCM.Merge.(glcmFeatC{n}) = pctDiff;
end

%RLM features
%Avg
rlmFeatC = fieldnames(IBSIfeatS.Original.rlmFeatS.AvgS);
for n = 1:length(rlmFeatC)
    ibsiVal = IBSIfeatS.Original.rlmFeatS.AvgS.(rlmFeatC{n});
    cerrVal = cerrFeatS.Original.rlmFeatS.AvgS.(rlmFeatC{n});
    pctDiff =(cerrVal-ibsiVal)*100/ibsiVal;
    pctDiffS.RLM.Avg.(rlmFeatC{n}) = pctDiff;
end
%Merge
rlmFeatC = fieldnames(IBSIfeatS.Original.rlmFeatS.CombS);
for n = 1:length(rlmFeatC)
    ibsiVal = IBSIfeatS.Original.rlmFeatS.CombS.(rlmFeatC{n});
    cerrVal = cerrFeatS.Original.rlmFeatS.CombS.(rlmFeatC{n});
    pctDiff =(cerrVal-ibsiVal)*100/ibsiVal;
    pctDiffS.RLM.Merge.(rlmFeatC{n}) = pctDiff;
end

%NGTDM features
ngtdmFeatC = fieldnames(IBSIfeatS.Original.ngtdmFeatS);
for n = 1:length(ngtdmFeatC)
    ibsiVal = IBSIfeatS.Original.ngtdmFeatS.(ngtdmFeatC{n});
    cerrVal = cerrFeatS.Original.ngtdmFeatS.(ngtdmFeatC{n});
    pctDiff =(cerrVal-ibsiVal)*100/ibsiVal;
    pctDiffS.NGTDM.(ngtdmFeatC{n}) = pctDiff;
end


%SZM features
szmFeatC = fieldnames(IBSIfeatS.Original.szmFeatS);
for n = 1:length(szmFeatC)
    ibsiVal = IBSIfeatS.Original.szmFeatS.(szmFeatC{n});
    cerrVal = cerrFeatS.Original.szmFeatS.(szmFeatC{n});
    pctDiff =(cerrVal-ibsiVal)*100/ibsiVal;
    pctDiffS.GLSZM.(szmFeatC{n}) = pctDiff;
end