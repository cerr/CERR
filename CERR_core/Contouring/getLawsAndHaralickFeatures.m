function [featuresM,volToEval,mask3M,minr,maxr,minc,maxc,mins,maxs] = getLawsAndHaralickFeatures(structNum,...
    rowMargin,colMargin,slcMargin,minIntensity,maxIntensity,planC,varargin)

% --- Optional inputs ---
% varargin{1} : haralOnlyFlag (default : 1)
% varargin{2} : Vector of flags indicating haralick textures to be computed
%               (default : all ones)
%               flagV = [energyFlg,entropyFlag,sumAvgFlg,homogFlg,...
%               contrastFlg,corrFlg,clustShadFlg,clustPromFlg,haralCorrFlg];
% varargin{3} : No. gray levels   (default:32 )
% varargin{4} : patchRadius       (default:[1,2])
% ------------------------
% AI 9/1/17 Also returns volToEval, mask3M, boundingbox coords
% AI 9/7/17 Added optional inputs

if ~exist('planC','var')
    global planC
end
indexS = planC{end};

% Get optional inputs
minargs = 7;
maxargs = 8;
nOptArgs = nargin - minargs;
optC = {1,ones(1,9),32,[1,2]};
[optC{1:nOptArgs}] = varargin{:};
[haralOnlyFlag,flagV,nLevel,patchRadius] = optC{:};

% get the region of interest
if ~iscell(structNum)
    [volToEval,maskBoundingBox3M] = ...
        getROI(structNum,rowMargin,colMargin,slcMargin,planC);
else
    volToEval = structNum{1};
    maskBoundingBox3M = structNum{2};
end

nanIntenityV = volToEval < -400;

% Generate Law's texture
if ~haralOnlyFlag
    % padd with mean intensities
    meanVol = nanmean(volToEval(:));
    if exist('padarray.m','file')
        paddedVolM = padarray(volToEval,[5 5 5],meanVol,'both');
    else
        paddedVolM = padarray_oct(volToEval,[5 5 5],meanVol,'both');
    end
    lawsMasksS = getLawsMasks();
    
    fieldNamesC = fieldnames(lawsMasksS);
    numFeatures = length(fieldNamesC);
    % initialize features matrix
    featuresM = zeros(sum(maskBoundingBox3M(~nanIntenityV)),numFeatures);
    for i = 1:numFeatures
        disp(i)
        text3M = convn(paddedVolM,lawsMasksS.(fieldNamesC{i}),'same');
        text3M = text3M(6:end-5,6:end-5,6:end-5);
        % featuresM(:,i) = text3M(maskBoundingBox3M); % for non cubic roi
        featuresM(:,i) = text3M(~nanIntenityV); % for the entire cubic roi
    end
    
else
    featuresM = [];
end

% Intensity as a feature
featuresM(:,end+1) = volToEval(~nanIntenityV);


% Filter intensities
nanIntenityV = volToEval < -400;
%nanIntenityV = false(size(nanIntenityV));
volToEval(nanIntenityV) = NaN;
% volToEval(volToEval > maxIntensity) = NaN;

% Genarate Haralick textures
separateDirnFlag = 1;
nOff = 1;
if separateDirnFlag
    offsetsM = getOffsets(2);
    nOff = size(offsetsM,1);
    numVox = sum(~nanIntenityV(:));
    nanIntenityV = repmat(nanIntenityV,[1 1 1 nOff]);
end

%featuresM = zeros(sum(maskBoundingBox3M(:)),0);
for patchSiz = patchRadius 
    
    patchSizeV  = [patchSiz patchSiz 0];
    
    for numGrLevels = nLevel
        offsetsM = getOffsets(2);
        
        % Haralick texture
        waitH = NaN;
        
        [energy3M,entropy3M,sumAvg3M,corr3M,invDiffMom3M,contrast3M,...
            clustShade3M,clustPromin3M,haralCorr3M] = gpuTextureByPatch(volToEval,...
            numGrLevels,patchSizeV,offsetsM,flagV,waitH,minIntensity,maxIntensity,separateDirnFlag);
        
        tempC = {energy3M,entropy3M,sumAvg3M,corr3M,invDiffMom3M,contrast3M,...
            clustShade3M,clustPromin3M,haralCorr3M};
        idx = find(flagV);
        for n = 1:length(idx)
            featuresM(:,end+1:end+nOff) = reshape(tempC{idx(n)}(~nanIntenityV),numVox,nOff);
        end
        
        
    end % gray level
end % patch radius
