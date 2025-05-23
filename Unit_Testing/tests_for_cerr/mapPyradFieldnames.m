function pyDictS = mapPyradFieldnames(pyDictS,imType,featClass)
%% Function to map pyradiomics  feature names to CERR feat names
%--------------------------------------------------------------------------
% INPUTS
% pyDictS    :  Python dictionary of radiomics features.
% imType     :  Image type. May be 'original','wavelet', or 'log'.
% featClass  :  Feature class. May be 'shape','firstorder','glcm','glrlm',
%               'ngtdm','ngldm', or 'glszm'.
%--------------------------------------------------------------------------
% AI 07/01/2020

switch(featClass)
    
    case 'shape'
        
        inC = {'shape_Elongation','shape_Flatness',....
            'shape_LeastAxisLength','shape_MajorAxisLength',...
            'shape_Maximum3DDiameter','shape_Maximum2DDiameterSlice',...
            'shape_Maximum2DDiameterColumn', 'shape_Maximum2DDiameterRow',...
            'shape_VoxelVolume','shape_MinorAxisLength',...
            'shape_Sphericity','shape_SurfaceArea',...
            'shape_SurfaceVolumeRatio'};
        inC = strcat([imType,'_'],inC);
        
        outC = {'elongation','flatness','leastAxis','majorAxis',...
            'max3dDiameter','max2dDiameterAxialPlane',...
            'max2dDiameterSagittalPlane','max2dDiameterCoronalPlane',...
            'volume','minorAxis','sphericity','surfArea',...
            'surfToVolRatio'};
        
    case 'firstorder'
        
        inC = {'firstorder_Minimum','firstorder_Maximum',...
            'firstorder_Mean','firstorder_Range','firstorder_Variance',...
            'firstorder_Median','firstorder_Skewness',...
            'firstorder_Kurtosis','firstorder_Entropy',...
            'firstorder_RootMeanSquared','firstorder_Energy',...
            'firstorder_TotalEnergy','firstorder_MeanAbsoluteDeviation',...
            'firstorder_10Percentile','firstorder_90Percentile',...
            'firstorder_RobustMeanAbsoluteDeviation',...
            'firstorder_InterquartileRange'};
        inC = strcat([imType,'_'],inC);
        
        
        outC = {'min','max','mean','range','var','median',...
            'skewness','kurtosis','entropy','rms','energy','totalEnergy',...
            'meanAbsDev','P10','P90','robustMeanAbsDev',...
            'interQuartileRange'};
        
    case 'glcm'
        
        inC = {'glcm_Autocorrelation','glcm_ClusterProminence',...
            'glcm_ClusterShade','glcm_ClusterTendency',...
            'glcm_Contrast','glcm_Correlation',...
            'glcm_DifferenceAverage','glcm_DifferenceEntropy',...
            'glcm_DifferenceVariance','glcm_Id','glcm_Idm',...
            'glcm_Idmn','glcm_Idn','glcm_Imc1',...
            'glcm_Imc2','glcm_InverseVariance',...
            'glcm_JointAverage','glcm_JointEnergy',...
            'glcm_JointEntropy','glcm_MaximumProbability',...
            'glcm_SumAverage','glcm_SumEntropy'};
        inC = strcat([imType,'_'],inC);
        
        outC = {'autoCorr','clustPromin','clustShade','clustTendency',...
            'contrast','corr','diffAvg','diffEntropy','diffVar','invDiff','invDiffMom',...
            'invDiffMomNorm','invDiffNorm','firstInfCorr','secondInfCorr','invVar',...
            'jointAvg','energy','jointEntropy','jointMax','sumAvg','sumEntropy'};
        
    case 'glrlm'
        
        inC = {'glrlm_GrayLevelNonUniformity',...
            'glrlm_GrayLevelNonUniformityNormalized','glrlm_GrayLevelVariance',...                  }
            'glrlm_HighGrayLevelRunEmphasis','glrlm_LongRunEmphasis',...
            'glrlm_LongRunHighGrayLevelEmphasis','glrlm_LongRunLowGrayLevelEmphasis',...
            'glrlm_LowGrayLevelRunEmphasis','glrlm_RunEntropy',...
            'glrlm_RunLengthNonUniformity','glrlm_RunLengthNonUniformityNormalized',...
            'glrlm_RunPercentage','glrlm_RunVariance','glrlm_ShortRunEmphasis',...
            'glrlm_ShortRunHighGrayLevelEmphasis','glrlm_ShortRunLowGrayLevelEmphasis'};
        inC = strcat([imType,'_'],inC);
        
        
        outC = {'grayLevelNonUniformity','grayLevelNonUniformityNorm','grayLevelVariance',...
            'highGrayLevelRunEmphasis','longRunEmphasis','longRunHighGrayLevelEmphasis',...
            'longRunLowGrayLevelEmphasis','lowGrayLevelRunEmphasis','runEntropy',...
            'runLengthNonUniformity','runLengthNonUniformityNorm','runPercentage',...
            'runLengthVariance','shortRunEmphasis','shortRunHighGrayLevelEmphasis',...
            'shortRunLowGrayLevelEmphasis'};
        
    case 'ngtdm'
        
        inC = {'ngtdm_Busyness','ngtdm_Coarseness',...
            'ngtdm_Complexity','ngtdm_Contrast','ngtdm_Strength'};
        inC = strcat([imType,'_'],inC);
        
        
        outC = {'busyness','coarseness','complexity','contrast','strength'};
        
    case 'ngldm'
        
        inC = {'gldm_DependenceEntropy','gldm_DependenceNonUniformity',...
            'gldm_DependenceNonUniformityNormalized','gldm_DependenceVariance',...
            'gldm_GrayLevelNonUniformity','gldm_GrayLevelVariance',...
            'gldm_HighGrayLevelEmphasis','gldm_LargeDependenceEmphasis',...
            'gldm_LargeDependenceHighGrayLevelEmphasis',...
            'gldm_LargeDependenceLowGrayLevelEmphasis',...
            'gldm_LowGrayLevelEmphasis','gldm_SmallDependenceEmphasis',...
            'gldm_SmallDependenceHighGrayLevelEmphasis',...
            'gldm_SmallDependenceLowGrayLevelEmphasis'};
        inC = strcat([imType,'_'],inC);
        
        
        outC = {'Entropy','DependenceCountNonuniformity',...
            'DependenceCountNonuniformityNorm','DependenceCountVariance',...
            'GrayLevelNonuniformity','GrayLevelVariance',...
            'HighGrayLevelCountEmphasis','HighDependenceEmphasis',...
            'HighDependenceHighGrayLevelEmphasis',...
            'HighDependenceLowGrayLevelEmphasis',...
            'LowGrayLevelCountEmphasis','LowDependenceEmphasis',...
            'LowDependenceHighGrayLevelEmphasis','LowDependenceLowGrayLevelEmphasis'};
        
        
    case 'glszm'
        
        inC = {'glszm_GrayLevelNonUniformity',...
            'glszm_GrayLevelNonUniformityNormalized',...
            'glszm_GrayLevelVariance',...
            'glszm_HighGrayLevelZoneEmphasis',...
            'glszm_LargeAreaEmphasis',...
            'glszm_LargeAreaHighGrayLevelEmphasis',...
            'glszm_LargeAreaLowGrayLevelEmphasis',...
            'glszm_LowGrayLevelZoneEmphasis',...
            'glszm_SizeZoneNonUniformity',...
            'glszm_SizeZoneNonUniformityNormalized',...
            'glszm_SmallAreaEmphasis',...
            'glszm_SmallAreaHighGrayLevelEmphasis',...
            'glszm_SmallAreaLowGrayLevelEmphasis',...
            'glszm_ZoneEntropy','glszm_ZonePercentage',...
            'glszm_ZoneVariance'};
        inC = strcat([imType,'_'],inC);
        
        
        outC = {'grayLevelNonUniformity','grayLevelNonUniformityNorm',...
            'grayLevelVariance','highGrayLevelZoneEmphasis','largeAreaEmphasis',...
            'largeAreaHighGrayLevelEmphasis','largeAreaLowGrayLevelEmphasis',...
            'lowGrayLevelZoneEmphasis','sizeZoneNonUniformity',...
            'sizeZoneNonUniformityNorm','smallAreaEmphasis',...
            'smallAreaHighGrayLevelEmphasis','smallAreaLowGrayLevelEmphasis',...
            'zoneEntropy','zonePercentage','sizeZoneVariance'};
        
end

for k  = 1:length(inC)
    
    pyDictS.(outC{k}) = pyDictS.(inC{k});
    pyDictS = rmfield(pyDictS,(inC{k}));
    
end

end
