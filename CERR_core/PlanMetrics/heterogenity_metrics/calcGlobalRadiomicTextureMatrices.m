function [textureS,paramS] = calcGlobalRadiomicTextureMatrices(paramFilename, planC)
% Wrapper to extract global radiomics texture matrices using JSON config
% file
%--------------------------------------------------------------------------
% INPUTS
% paramFilename  :  PAth to JSON config file
% planC
%
% AI 4/2/2020 Created scripts for pre-processing & feature extraction
%--------------------------------------------------------------------------

%Read JSON parameter file
paramS = getRadiomicsParamTemplate(paramFilename);

%Pre-processing
indexS = planC{end};
strC = {planC{indexS.structures}.structureName};
strName = paramS.structuresC{1};
structNum = getMatchingIndex(strName,strC,'EXACT');
scanNum = getStructureAssociatedScan(structNum,planC);
[volToEval,maskBoundingBox3M] =  preProcessForRadiomics(scanNum,...
    structNum, paramS, planC);

%Quantization
minClipIntensity = paramS.textureParamS.minClipIntensity;
maxClipIntensity = paramS.textureParamS.maxClipIntensity;

if quantizeFlag
    numGrLevels = [];
    binwidth = [];
    if isfield(paramS.textureParamS,'numGrLevels')
        numGrLevels = paramS.textureParamS.numGrLevels;
    end
    if isfield(paramS.textureParamS,'binwidth')
        binwidth = paramS.textureParamS.binwidth;
    end
    % Don't use intensities outside the ROI in discretization
    volToEval(~maskBoundingBox3M) = NaN;
    quantized3M = imquantize_cerr(volToEval,numGrLevels,...
        minClipIntensity,maxClipIntensity,binwidth);
    % Reassign the number of gray levels in case they were computed for the
    % passed binwidth
    numGrLevels = max(quantized3M(:));
    paramS.textureParamS.numGrLevels = numGrLevels;
    
else
    quantized3M = volToEval;
end
quantized3M(~maskBoundingBox3M) = NaN;

%Calc texture matrices
textureS = struct();

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
    
    switch lower(avgType)
        case 'texturematrix'
            %Haralick features with combined cooccurrence matrix
            cooccurType = 1;
        case 'feature'
            %'Haralick features from separate cooccurrence matrix per direction, averaged'
            cooccurType = 2;
        otherwise
            error('Invalid input. Directionality must be "2D" or "3D"');
    end
    
    offsetsM = getOffsets(dirctn);
    textureS.GLCM = calcCooccur(quantized3M, offsetsM, ...
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
    textureS.GTDM = calcNGTDM(quantized3M, paramS.textureParamS.patchRadiusVox, ....
        paramS.textureParamS.numGrLevels,[]);
end

if paramS.whichFeatS.gldm.flag
    textureS.GLDM = calcCooccur(quantized3M, paramS.textureParamS.patchRadiusVox,...
        paramS.textureParamS.numGrLevels, paramS.textureParamS.imgDiffThresh, []);
end

if paramS.whichFeatS.glszm.flag
    textureS.GLSZM = calcCooccur(quantized3M, paramS.textureParamS.numGrLevels,...
        paramS.textureParamS.szmType);
end


end