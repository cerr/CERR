function [textureS, paramS] = calcGlobalRadiomicTextureMatrices(paramFilename, planC)
% Wrapper to extract global radiomics texture matrices using JSON config
% file
%--------------------------------------------------------------------------
% INPUTS
% paramFilename  :  Path to JSON config file
% planC
%--------------------------------------------------------------------------
% AI 4/2/2020 

%% Read JSON parameter file
paramS = getRadiomicsParamTemplate(paramFilename);

%% Pre-processing
indexS = planC{end};
strC = {planC{indexS.structures}.structureName};
strName = paramS.structuresC{1};
structNum = getMatchingIndex(strName,strC,'EXACT');
scanNum = getStructureAssociatedScan(structNum,planC);
[volToEval,maskBoundingBox3M,gridS,paramS] =  preProcessForRadiomics(scanNum,...
    structNum, paramS, planC);
textureS = struct();

%% Get image types
fieldNamC = fieldnames(paramS.imageType);
imageTypeC = {};
for iImg = 1:length(fieldNamC)
    for iFilt = 1:length(paramS.imageType.(fieldNamC{iImg}))
        filtParamS = struct();
        filtParamS.imageType = fieldNamC{iImg};
        filtParamS.paramS = paramS.imageType.(fieldNamC{iImg})(iFilt);
        imageTypeC{end+1} = filtParamS;
    end
end

%% Loop over image types
for k = 1:length(imageTypeC)
    
    %Generate volume based on original/derived imageType
    if strcmpi(imageTypeC{k}.imageType,'original')
        quantizeFlag = paramS.toQuantizeFlag;
        minClipIntensity = paramS.textureParamS.minClipIntensity;
        maxClipIntensity = paramS.textureParamS.maxClipIntensity;
    else
        outS = processImage(imageTypeC{k}.imageType,volOrig3M,maskBoundingBox3M,...
            imageTypeC{k}.paramS);
        derivedImgName = fieldnames(outS);
        volToEval = outS.(derivedImgName{1});
        quantizeFlag = true;   % always quantize derived images
        minClipIntensity = []; % no clipping imposed for derived images
        maxClipIntensity = []; % no clipping imposed for derived images
    end
    
    %Quantize
    if quantizeFlag
        numGrLevels = [];
        binwidth = [];
        if isfield(paramS.textureParamS,'numGrLevels')
            numGrLevels = paramS.textureParamS.numGrLevels;
        end
        if isfield(paramS.textureParamS,'binwidth')
            binwidth = paramS.textureParamS.binwidth;
        end
        % Exclude intensities outside the ROI
        volToEval(~maskBoundingBox3M) = NaN;
        quantized3M = imquantize_cerr(volToEval,numGrLevels,...
            minClipIntensity,maxClipIntensity,binwidth);
        % Update number of gray levels if binwidth was specified
        numGrLevels = max(quantized3M(:));
        paramS.textureParamS.numGrLevels = numGrLevels;
    else
        quantized3M = volToEval;
    end
    quantized3M(~maskBoundingBox3M) = NaN;
    
    
    %Calculate texture matrices
    outFieldName = createFieldNameFromParameters...
        (imageTypeC{k}.imageType,imageTypeC{k}.paramS);
    
    if paramS.whichFeatS.glcm.flag
        
        directionality = paramS.textureParamS.directionality;
        switch lower(directionality)
            case '2d'
                dirctn = 2;
            case '3d'
                dirctn = 1;
            otherwise
                error('Invalid input. Directionality must be "2D" or "3D"');
        end
        
        switch lower(paramS.textureParamS.avgType)
            case 'texturematrix'
                %Haralick features with combined cooccurrence matrix
                cooccurType = 1;
            case 'feature'
                %'Haralick features from separate cooccurrence matrix per direction, averaged'
                cooccurType = 2;
            otherwise
                error('Invalid input. Supported avg types: "texturematrix", "feature".');
        end
        
        offsetsM = getOffsets(dirctn);
        textureS.(outFieldName).GLCM = calcCooccur(quantized3M, offsetsM, ...
            paramS.textureParamS.numGrLevels, cooccurType);
    end
    
    if paramS.whichFeatS.glrlm.flag
        directionality = paramS.textureParamS.directionality;
        switch lower(directionality)
            case '2d'
                dirctn = 2;
            case '3d'
                dirctn = 1;
            otherwise
                error('Invalid input. Directionality must be "2D" or "3D"');
        end
        offsetsM = getOffsets(dirctn);
        textureS.GLRLM = calcRLM(quantized3M, offsetsM,...
            paramS.textureParamS.numGrLevels, paramS.textureParamS.rlmType);
    end
    
    if paramS.whichFeatS.gtdm.flag
        textureS.(outFieldName).GTDM = calcNGTDM(quantized3M, paramS.textureParamS.patchRadiusVox, ....
            paramS.textureParamS.numGrLevels);
    end
    
    if paramS.whichFeatS.gldm.flag
        textureS.(outFieldName).GLDM = calcNGLDM(quantized3M, paramS.textureParamS.patchRadiusVox,...
            paramS.textureParamS.numGrLevels, paramS.textureParamS.imgDiffThresh);
    end
    
    if paramS.whichFeatS.glszm.flag
        textureS.(outFieldName).GLSZM = calcSZM(quantized3M, paramS.textureParamS.numGrLevels,...
            paramS.textureParamS.szmType);
    end
    
end

end