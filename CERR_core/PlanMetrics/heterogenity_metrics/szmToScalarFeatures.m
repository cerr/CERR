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
% flagS.sae = 1;
% flagS.lae = 1;
% flagS.gln = 1;
% flagS.glv = 1;
% flagS.szv = 1;
% flagS.glnNorm
% flagS.szn = 1;
% flagS.sznNorm
% flagS.zp = 1;
% flagS.lglze = 1;
% flagS.hglze = 1;
% flagS.salgle = 1;
% flagS.sahgle = 1;
% flagS.lalgle = 1;
% flagS.larhgle = 1;
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
if flagS.sae
    saeM = bsxfun(@rdivide,szmM,lenV.^2);
    featureS.sae = sum(saeM(:))/sum(szmM(:));
end

% Large Area Emphasis (LAE) (Aerts et al, Nature suppl. eq. 46)
if flagS.lae
    laeM = bsxfun(@times,szmM,lenV.^2);
    featureS.lae = sum(laeM(:))/sum(szmM(:));
end

% Gray Level Non-Uniformity (GLN) (Aerts et al, Nature suppl. eq. 47)
if flagS.gln
    featureS.gln = sum(sum(szmM,2).^2) / sum(szmM(:));
end

if flagS.glnNorm
    featureS.glnNorm = sum(sum(szmM,2).^2) / sum(szmM(:))^2;
end

% Size Zone Non-Uniformity (SZN) (Aerts et al, Nature suppl. eq. 48)
if flagS.szn
    featureS.szn = sum(sum(szmM,1).^2) / sum(szmM(:));
end

% Size Zone Non-Uniformity Normalized (SZNN) (Aerts et al, Nature suppl. eq. 48)
if flagS.sznNorm
    featureS.sznNorm = sum(sum(szmM,1).^2) / sum(szmM(:))^2;
end

% Zone Percentage (ZP) (Aerts et al, Nature suppl. eq. 49)
if flagS.zp
    if isempty(numVoxels)
        numVoxels = 1;
    end
    featureS.zp = sum(szmM(:)) / numVoxels;
end

% Low Gray Level Zone Emphasis (LGLZE) (Aerts et al, Nature suppl. eq. 50)
if flagS.lglze
    lglzeM = bsxfun(@rdivide,szmM',levV.^2);
    featureS.lglze = sum(lglzeM(:)) / sum(szmM(:));
end

% High Gray Level Zone Emphasis (HGLZE) (Aerts et al, Nature suppl. eq. 51)
if flagS.hglze
    hglzeM = bsxfun(@times,szmM',levV.^2);
    featureS.hglze = sum(hglzeM(:)) / sum(szmM(:));
end

% Small Area Low Gray Level Emphasis (SALGLE) (Aerts et al, Nature suppl. eq. 52)
if flagS.salgle
    levLenM = bsxfun(@times,(levV').^2,lenV.^2);
    salgleM = bsxfun(@rdivide,szmM,levLenM);
    featureS.salgle = sum(salgleM(:)) / sum(szmM(:));
end

% Small Area High Gray Level Emphasis (SAHGLE) (Aerts et al, Nature suppl. eq. 53)
if flagS.sahgle
    levLenM = bsxfun(@times,(levV').^2,1./lenV.^2);
    sahgleM = bsxfun(@times,szmM,levLenM);
    featureS.sahgle = sum(sahgleM(:)) / sum(szmM(:));
end

% Large Area Low Gray Level Emphasis (LALGLE) (Aerts et al, Nature suppl. eq. 54)
if flagS.lalgle
    levLenM = bsxfun(@times,1./(levV').^2,lenV.^2);
    lalgleM = bsxfun(@times,szmM,levLenM);
    featureS.lalgle = sum(lalgleM(:)) / sum(szmM(:));
end

% Large Area High Gray Level Emphasis (LAHGLE) (Aerts et al, Nature suppl. eq. 55)
if flagS.lahgle
    levLenM = bsxfun(@times,(levV').^2,lenV.^2);
    lahgleM = bsxfun(@times,szmM,levLenM);
    featureS.lahgle = sum(lahgleM(:)) / sum(szmM(:));
end

% Grey Level Variance
if flagS.glv
    iPij = bsxfun(@times,szmM'/sum(szmM(:)),levV);
    mu = sum(iPij(:));
    iMinusMuPij = bsxfun(@times,szmM'/sum(szmM(:)),(levV-mu).^2);
    featureS.glv = sum(iMinusMuPij(:));
end

% Size Zone Variance
if flagS.szv
    jPij = bsxfun(@times,szmM/sum(szmM(:)),lenV);
    mu = sum(jPij(:));
    jMinusMuPij = bsxfun(@times,szmM/sum(szmM(:)),(lenV-mu).^2);
    featureS.szv = sum(jMinusMuPij(:));
end

%Zone Entropy
if flagS.ze
    zoneSum = sum(szmM(:));
    featureS.ze = -sum(szmM(:)/zoneSum .* log2(szmM(:)/zoneSum + eps));
end
