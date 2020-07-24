function radiomicsParamS = getRadiomicsParamTemplate(paramFilename,dictS)
% radiomicsParamS = getRadiomicsParamTemplate(paramFilename);
%
% Template parameters for radiomics feature extraction
%
% --------------------------------------------------------------------------------------
% INPUT:
% paramFileName : Path to JSON file for radiomics feature extraction.
%                 Sample JSON file: CERR_core/PlanMetrics/heterogenity_metrics/sample_radiomics_extraction_settings.json
%
% dictS       : Alternatively, pass dictionary userInS
% --------------------------------------------------------------------------------------
%
% APA, 2/27/2019
% AI, 3/22/19     Modified for compatibility with JSON input

feature accel off

%% Read JSON file
if ~isempty(paramFilename)
    userInS = jsondecode(fileread(paramFilename));
else
    userInS = dictS;
end

%% Get image type
filterTypeC = fieldnames(userInS.imageType);
radiomicsParamS.imageType = struct();
for m = 1:length(filterTypeC)
    paramListC = fieldnames(userInS.imageType.(filterTypeC{m}));
    radiomicsParamS.imageType.(filterTypeC{m}) = struct();
    for n = 1:length(paramListC)
        for iFilt = 1:length(userInS.imageType.(filterTypeC{m}))
            radiomicsParamS.imageType.(filterTypeC{m})(iFilt).(paramListC{n}).val = ...
                userInS.imageType.(filterTypeC{m})(iFilt).(paramListC{n});
        end
    end
end


%% Calculation Parameters
if isfield(userInS,'settings')
    settingsC = fieldnames(userInS.settings);
    firstOrderParamS = struct;
    textureParamS = struct;
    shapeParamS = struct;
    peakValleyParamS = struct;
    ivhParamS = struct;
    
    % Structure names
    if isfield(userInS,'structures')
        radiomicsParamS.structuresC = userInS.structures;
    end
    %Otherwise, use entire scan
    
    % ---1. First-order features ---
    idx = strcmpi(settingsC,'firstOrder');
    if any(idx)
        paramC = fieldnames(userInS.settings.(settingsC{idx}));
        for k = 1: length(paramC)
            firstOrderParamS.(paramC{k}) = userInS.settings.(settingsC{idx}).(paramC{k});
        end
        radiomicsParamS.firstOrderParamS = firstOrderParamS;
    end
    
    %---2. Shape features ----
    idx = strcmpi(settingsC,'shape');
    if any(idx)
        paramC = fieldnames(userInS.settings.(settingsC{idx}));
        for k = 1: length(paramC)
            shapeParamS.(paramC{k}) = userInS.settings.(settingsC{idx}).(paramC{k});
        end
        radiomicsParamS.shapeParamS = shapeParamS;
    end
    
    %---3. Higher-order (texture) features ----
    idx = strcmpi(settingsC,'texture');
    if any(idx)
        paramC = fieldnames(userInS.settings.(settingsC{idx}));
        for k = 1: length(paramC)
            textureParamS.(paramC{k}) = userInS.settings.(settingsC{idx}).(paramC{k});
        end
        radiomicsParamS.textureParamS = textureParamS;
    end
    
    %---4. Peak-valley features ----
    idx = strcmpi(settingsC,'peakvalley');
    if any(idx)
        paramC = fieldnames(userInS.settings.(settingsC{idx}));
        for k = 1: length(paramC)
            peakValleyParamS.(paramC{k}) = userInS.settings.(settingsC{idx}).(paramC{k});
        end
        radiomicsParamS.peakValleyParamS = peakValleyParamS;
    end
    
    %---5. IVH features ----
    idx = strcmpi(settingsC,'ivh');
    if any(idx)
        paramC = fieldnames(userInS.settings.(settingsC{idx}));
        for k = 1: length(paramC)
            ivhParamS.(paramC{k}) = userInS.settings.(settingsC{idx}).(paramC{k});
        end
        radiomicsParamS.ivhParamS = ivhParamS;
    end
    
    
    %% Set flags for sub-classes of features to be extracted
    whichFeatS = struct('resample',struct('flag',0), 'padding',struct('flag',0),...
        'perturbation',struct('flag',0),'firstOrder',struct('flag',0),...
        'shape',struct('flag',0),'texture',struct('flag',0),...
        'peakValley',struct('flag',0),'ivh',struct('flag',0),'glcm',struct('flag',0),...
        'glrlm',struct('flag',0),'gtdm',struct('flag',0),'gldm',struct('flag',0),...
        'glszm',struct('flag',0));
    for k = 1:length(settingsC)
        fieldNamC = fieldnames(userInS.settings.(settingsC{k}));
        if ~isempty(fieldNamC)
            whichFeatS.(settingsC{k}).flag = 1;
            for iField = 1:length(fieldNamC)
                whichFeatS.(settingsC{k}).(fieldNamC{iField}) = userInS.settings...
                    .(settingsC{k}).(fieldNamC{iField});
            end
        end
    end
end

if isfield(userInS,'featureClass')
    inputClassesC = fieldnames(userInS.featureClass);
    for k =1:length(inputClassesC)
        whichFeatS.(inputClassesC{k}).flag = 1;
        if isfield(userInS.featureClass.(inputClassesC{k}),'featureList')
            whichFeatS.(inputClassesC{k}).featureList = ...
                userInS.featureClass.(inputClassesC{k}).featureList;
        else
            whichFeatS.(inputClassesC{k}).featureList = {'all'};
        end
    end
    radiomicsParamS.whichFeatS = whichFeatS;
    
    %% Flag to quantize input data
    radiomicsParamS.toQuantizeFlag = 1;
else
    radiomicsParamS.whichFeatS = whichFeatS;
end

feature accel on
