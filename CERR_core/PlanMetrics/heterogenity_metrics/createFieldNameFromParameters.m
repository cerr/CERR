function fieldName = createFieldNameFromParameters(imageType,settingS)
% createFieldNamesFromParameters(imageType,settingS)
%
% Create unique fieldname for radiomics features returned by
% calcRadiomicsForImgType
%
% -------------------------------------------------------------------------
% INPUTS
% imageType : 'Original' or filtered image type (see processImage.m for valid options)
% settingS  : Parameter dictionary for radiomics feature extraction
% -------------------------------------------------------------------------
%
% AI 4/2/19

%settingS = paramS.imageType.(imageType);

switch(lower(imageType))
    
    case {'original','sobel'}
        fieldName = imageType;
        
    case 'haralickcooccurance'
        dirC = {'3d','2d'};
        dir = dirC{settingS.Directionality.val};
        settingsStr = [settingS.Type.val,'_',dir,'_',...
            num2str(settingS.NumLevels.val),'levels_patchsize',...
            num2str(settingS.PatchSize.val(1)),num2str(settingS.PatchSize.val(2)),...
            num2str(settingS.PatchSize.val(3))];
        fieldName = [imageType,'_',settingsStr];
        
    case 'wavelets'
        settingsStr = [settingS.Wavelets.val,'_',num2str(settingS.Index.val),'_',settingS.Direction.val];
        fieldName = [imageType,'_',settingsStr];
        
    case 'log'
        settingsStr = ['sigma_',num2str(settingS.Sigma_mm.val),'mm'];
        fieldName = [imageType,'_',settingsStr];
        
    case 'gabor'
        settingsStr = ['radius',num2str(settingS.Radius.val),'_sigma',...
            num2str(settingS.Sigma.val),'_AR',num2str(settingS.AspectRatio.val),...
            '_',num2str(settingS.Orientation.val),'_deg_wavelength',...
            num2str(settingS.Wavlength.val)];
        fieldName = [imageType,'_',settingsStr];
        
    case 'firstorderstatistics'
        settingsStr = ['patchsize',num2str(settingS.PatchSize.val(1)),...
            '_voxelvol',num2str(settingS.VoxelVolume.val)];
        fieldName = ['firstOrderStatistics','_',settingsStr];
        
    case 'lawsconvolution'
        dirC = {'2d','3d'};
        settingsStr = [dirC{settingS.Direction.val},'_kernelSize',...
            num2str(settingS.KernelSize.val)];
        fieldName = [imageType,'_',settingsStr];
        
    case 'collage'
        settingsStr = [settingS.Dimension.val,'_',...
            num2str(settingS.Number_Gray_Levels.val),'bins_','dominantRadius'...
            num2str(settingS.Dominant_Dir_Radius.val(1)),'_cooccurRadius',...
            num2str(settingS.Cooccur_Radius.val(1))];
        fieldName = [imageType,'_',settingsStr];
        
    case 'simpleitk'
        sitkFilter = settingS.sitkFilterName.val;
        switch lower(sitkFilter)
            case 'laplacianrecursivegaussianimagefilter'
                settingsStr = ['sigma_mm_',num2str(settingS.params.val.Sigma_mm)];
        end        
        fieldName = [imageType,'_',sitkFilter,'_',settingsStr];
        
    case 'suv'
        suvType = settingS.suvType.val;
        fieldName = [imageType,'_',suvType];
        
end

%Ensure valid fieldname
fieldName = strrep(fieldName,' ','');
fieldName = strrep(fieldName,'.','_');

end