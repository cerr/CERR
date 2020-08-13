function featureS = szmToScalarFeatures(szmM, numVoxels, flagS)
% function featureS = szmToScalarFeatures(szmM, numVoxels, flagS)
%
% INPUT:  szmM of size nL x maxLength (in units of number of voxels)
%         flagS is a structure with feature names as its fields.
%         The values represent flags to calculate (or not) that particular feature.
%         EXAMPLE:
%         ** flagS.sre = 1;
%            flagS.lre = 0;
%            flagS.rln = 1;
% OUTPUT: featureS is a structure array with scalar texture features as its
%         fields. Each field's value is a vector containing the feature values
%         for each szmM
%
% EXAMPLE:
%
% numRows = 10;
% numCols = 10;
% numSlcs = 1;
% 
% % get directions
% offsetM = getOffsets(1);
% 
% % number of gray levels
% nL = 3;
% 
% % create an image with random numbers
% imgM = randi(nL,numRows,numCols,numSlcs);
% 
% 2-d or 3-d zones
% szmType = 1;
%
% % call the rlm calculator
% szmM = calcSZM(quantizedM, nL, szmType)
% 
% % define feature flags
% szmFlagS.grayLevelNonUniformity = 1;
% szmFlagS.grayLevelNonUniformityNorm = 1;
% szmFlagS.grayLevelVariance = 1;
% szmFlagS.highGrayLevelZoneEmphasis = 1;
% szmFlagS.lowGrayLevelZoneEmphasis = 1;
% szmFlagS.largeAreaEmphasis = 1;
% szmFlagS.largeAreaHighGrayLevelEmphasis = 1;
% szmFlagS.largeAreaLowGrayLevelEmphasis = 1;
% szmFlagS.sizeZoneNonUniformity = 1;
% szmFlagS.sizeZoneNonUniformityNorm = 1;
% szmFlagS.sizeZoneVariance = 1;
% szmFlagS.zonePercentage = 1;
% szmFlagS.smallAreaEmphasis = 1;
% szmFlagS.smallAreaLowGrayLevelEmphasis = 1;
% szmFlagS.smallAreaHighGrayLevelEmphasis = 1;
% szmFlagS.zoneEntropy = 1;
%
% % Number of voxels
% numVoxels = numel(imgM);
%
% % Convert RLM matrix to scalar features
% featureS = rlmToScalarFeatures(szmM, numVoxels, flagS);
%
%
% APA, 3/02/2018

nL = size(szmM,1);
lenV = 1:size(szmM,2);
levV = 1:nL;

% Small Area Emphasis (SAE) (Aerts et al, Nature suppl. eq. 45)
if flagS.smallAreaEmphasis
    saeM = bsxfun(@rdivide,szmM,lenV.^2);
    featureS.smallAreaEmphasis = sum(saeM(:))/sum(szmM(:));
end

% Large Area Emphasis (LAE) (Aerts et al, Nature suppl. eq. 46)
if flagS.largeAreaEmphasis
    laeM = bsxfun(@times,szmM,lenV.^2);
    featureS.largeAreaEmphasis = sum(laeM(:))/sum(szmM(:));
end

% Gray Level Non-Uniformity (GLN) (Aerts et al, Nature suppl. eq. 47)
if flagS.grayLevelNonUniformity
    featureS.grayLevelNonUniformity = sum(sum(szmM,2).^2) / sum(szmM(:));
end

if flagS.grayLevelNonUniformityNorm
    featureS.grayLevelNonUniformityNorm = sum(sum(szmM,2).^2) / sum(szmM(:))^2;
end

% Size Zone Non-Uniformity (SZN) (Aerts et al, Nature suppl. eq. 48)
if flagS.sizeZoneNonUniformity
    featureS.sizeZoneNonUniformity = sum(sum(szmM,1).^2) / sum(szmM(:));
end

% Size Zone Non-Uniformity Normalized (SZNN) (Aerts et al, Nature suppl. eq. 48)
if flagS.sizeZoneNonUniformityNorm
    featureS.sizeZoneNonUniformityNorm = sum(sum(szmM,1).^2) / sum(szmM(:))^2;
end

% Zone Percentage (ZP) (Aerts et al, Nature suppl. eq. 49)
if flagS.zonePercentage
    if isempty(numVoxels)
        numVoxels = 1;
    end
    featureS.zonePercentage = sum(szmM(:)) / numVoxels;
end

% Low Gray Level Zone Emphasis (LGLZE) (Aerts et al, Nature suppl. eq. 50)
if flagS.lowGrayLevelZoneEmphasis
    lglzeM = bsxfun(@rdivide,szmM',levV.^2);
    featureS.lowGrayLevelZoneEmphasis = sum(lglzeM(:)) / sum(szmM(:));
end

% High Gray Level Zone Emphasis (HGLZE) (Aerts et al, Nature suppl. eq. 51)
if flagS.highGrayLevelZoneEmphasis
    hglzeM = bsxfun(@times,szmM',levV.^2);
    featureS.highGrayLevelZoneEmphasis = sum(hglzeM(:)) / sum(szmM(:));
end

% Small Area Low Gray Level Emphasis (SALGLE) (Aerts et al, Nature suppl. eq. 52)
if flagS.smallAreaLowGrayLevelEmphasis
    levLenM = bsxfun(@times,(levV').^2,lenV.^2);
    salgleM = bsxfun(@rdivide,szmM,levLenM);
    featureS.smallAreaLowGrayLevelEmphasis = sum(salgleM(:)) / sum(szmM(:));
end

% Small Area High Gray Level Emphasis (SAHGLE) (Aerts et al, Nature suppl. eq. 53)
if flagS.smallAreaHighGrayLevelEmphasis
    levLenM = bsxfun(@times,(levV').^2,1./lenV.^2);
    sahgleM = bsxfun(@times,szmM,levLenM);
    featureS.smallAreaHighGrayLevelEmphasis = sum(sahgleM(:)) / sum(szmM(:));
end

% Large Area Low Gray Level Emphasis (LALGLE) (Aerts et al, Nature suppl. eq. 54)
if flagS.largeAreaLowGrayLevelEmphasis
    levLenM = bsxfun(@times,1./(levV').^2,lenV.^2);
    lalgleM = bsxfun(@times,szmM,levLenM);
    featureS.largeAreaLowGrayLevelEmphasis = sum(lalgleM(:)) / sum(szmM(:));
end

% Large Area High Gray Level Emphasis (LAHGLE) (Aerts et al, Nature suppl. eq. 55)
if flagS.largeAreaHighGrayLevelEmphasis
    levLenM = bsxfun(@times,(levV').^2,lenV.^2);
    lahgleM = bsxfun(@times,szmM,levLenM);
    featureS.largeAreaHighGrayLevelEmphasis = sum(lahgleM(:)) / sum(szmM(:));
end

% Grey Level Variance
if flagS.grayLevelVariance
    iPij = bsxfun(@times,szmM'/sum(szmM(:)),levV);
    mu = sum(iPij(:));
    iMinusMuPij = bsxfun(@times,szmM'/sum(szmM(:)),(levV-mu).^2);
    featureS.grayLevelVariance = sum(iMinusMuPij(:));
end

% Size Zone Variance
if flagS.sizeZoneVariance
    jPij = bsxfun(@times,szmM/sum(szmM(:)),lenV);
    mu = sum(jPij(:));
    jMinusMuPij = bsxfun(@times,szmM/sum(szmM(:)),(lenV-mu).^2);
    featureS.sizeZoneVariance = sum(jMinusMuPij(:));
end

%Zone Entropy
if flagS.zoneEntropy
    zoneSum = sum(szmM(:));
    featureS.zoneEntropy = -sum(szmM(:)/zoneSum .* log2(szmM(:)/zoneSum + eps));
end
