function textureS = calcGlobalRadiomicTextureMatrices(paramFilename, planC)
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

%Quantize
fieldListC = {'numGrLevels','clipMin','clipMax','binWidth'};
for n = 1:length(fieldListC)
    if ~isfield(paramS.textureParamS,fieldListC{n})
        paramS.textureParamS.(fieldListC{n}) = [];
    end
end
quantized3M = imquantize_cerr(volToEval,paramS.textureParamS.numGrLevels,...
    paramS.textureParamS.clipMin,paramS.textureParamS.clipMax,...
    paramS.textureParamS.binWidth);
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
    offsetsM = getOffsets(dirctn);
    textureS.GLCM = calcCooccur(quantized3M, offsetsM, ...
        paramS.textureParamS.numGrLevels, paramS.textureParamS.avgType);
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