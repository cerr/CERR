function featureS = rlmToScalarFeatures(rlmM, numVoxels, flagS)
% function featureS = rlmToScalarFeatures(rlmM, numVoxels, flagS)
%
% INPUT:  rlmM of size nL x maxLength (in units of number of voxels)
%         flagS is a structure with feature names as its fields.
%         The values represent flags to calculate (or not) that particular feature.
%         EXAMPLE:
%         ** flagS.sre = 1;
%            flagS.lre = 0;
%            flagS.rln = 1;
% OUTPUT: featureS is a structure array with scalar texture features as its
%         fields. Each field's value is a vector containing the feature values
%         for each rlmM
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
% % set option to add run lengths from all directions
% rlmType = 1;
% 
% % call the rlm calculator
% rlmM = calcRLM(imgM, offsetM, nL, rlmType);
% 
% % define feature flags
% flagS.sre = 1;
% flagS.lre = 1;
% flagS.gln = 1;
% flagS.glnNorm = 1;
% flagS.rln = 1;
% flagS.rlnNorm = 1;
% flagS.rp = 1;
% flagS.lglre = 1;
% flagS.hglre = 1;
% flagS.srlgle = 1;
% flagS.srhgle = 1;
% flagS.lrlgle = 1;
% flagS.lrhgle = 1;
% flagS.glv = 1;
% flagS.rlv = 1;
% flagS.re = 1;
%
% % Number of voxels
% numVoxels = numel(imgM);
%
% % Convert RLM matrix to scalar features
% featureS = rlmToScalarFeatures(rlmM, numVoxels, flagS);
%
%
% APA, 10/04/2016

nL = size(rlmM,1);
lenV = 1:size(rlmM,2);
levV = 1:nL;

% Short Run Emphasis (SRE) (Aerts et al, Nature suppl. eq. 45)
if flagS.sre
    sreM = bsxfun(@rdivide,rlmM,lenV.^2);
    featureS.sre = sum(sreM(:))/sum(rlmM(:));
end

% Long Run Emphasis (LRE) (Aerts et al, Nature suppl. eq. 46)
if flagS.lre
    lreM = bsxfun(@times,rlmM,lenV.^2);
    featureS.lre = sum(lreM(:))/sum(rlmM(:));
end

% Gray Level Non-Uniformity (GLN) (Aerts et al, Nature suppl. eq. 47)
if flagS.gln
    featureS.gln = sum(sum(rlmM,2).^2) / sum(rlmM(:));
end

if flagS.glnNorm
    featureS.glnNorm = sum(sum(rlmM,2).^2) / sum(rlmM(:))^2;
end

% Run Length Non-Uniformity (RLN) (Aerts et al, Nature suppl. eq. 48)
if flagS.rln
    featureS.rln = sum(sum(rlmM,1).^2) / sum(rlmM(:));
end

if flagS.rlnNorm
    featureS.rlnNorm = sum(sum(rlmM,1).^2) / sum(rlmM(:))^2;
end

% Run Percentage (RP) (Aerts et al, Nature suppl. eq. 49)
if flagS.rp
    if isempty(numVoxels)
        numVoxels = 1;
    end
    featureS.rp = sum(rlmM(:)) / numVoxels;
end

% Low Gray Level Run Emphasis (LGLRE) (Aerts et al, Nature suppl. eq. 50)
if flagS.lglre
    lglreM = bsxfun(@rdivide,rlmM',levV.^2);
    featureS.lglre = sum(lglreM(:)) / sum(rlmM(:));
end

% High Gray Level Run Emphasis (HGLRE) (Aerts et al, Nature suppl. eq. 51)
if flagS.hglre
    hglreM = bsxfun(@times,rlmM',levV.^2);
    featureS.hglre = sum(hglreM(:)) / sum(rlmM(:));
end

% Short Run Low Gray Level Emphasis (SRLGLE) (Aerts et al, Nature suppl. eq. 52)
if flagS.srlgle
    levLenM = bsxfun(@times,(levV').^2,lenV.^2);
    srlgleM = bsxfun(@rdivide,rlmM,levLenM);
    featureS.srlgle = sum(srlgleM(:)) / sum(rlmM(:));
end

% Short Run High Gray Level Emphasis (SRHGLE) (Aerts et al, Nature suppl. eq. 53)
if flagS.srhgle
    levLenM = bsxfun(@times,(levV').^2,1./lenV.^2);
    srhgleM = bsxfun(@times,rlmM,levLenM);
    featureS.srhgle = sum(srhgleM(:)) / sum(rlmM(:));
end

% Long Run Low Gray Level Emphasis (LRLGLE) (Aerts et al, Nature suppl. eq. 54)
if flagS.lrlgle
    levLenM = bsxfun(@times,1./(levV').^2,lenV.^2);
    lrlgleM = bsxfun(@times,rlmM,levLenM);
    featureS.lrlgle = sum(lrlgleM(:)) / sum(rlmM(:));
end

% Long Run High Gray Level Emphasis (LRHGLE) (Aerts et al, Nature suppl. eq. 55)
if flagS.lrhgle
    levLenM = bsxfun(@times,(levV').^2,lenV.^2);
    lrhgleM = bsxfun(@times,rlmM,levLenM);
    featureS.lrhgle = sum(lrhgleM(:)) / sum(rlmM(:));
end

% Grey Level Variance
if flagS.glv
    iPij = bsxfun(@times,rlmM'/sum(rlmM(:)),levV);
    mu = sum(iPij(:));
    iMinusMuPij = bsxfun(@times,rlmM'/sum(rlmM(:)),(levV-mu).^2);
    featureS.glv = sum(iMinusMuPij(:));
end

% Run Length Variance
if flagS.rlv
    jPij = bsxfun(@times,rlmM/sum(rlmM(:)),lenV);
    mu = sum(jPij(:));
    jMinusMuPij = bsxfun(@times,rlmM/sum(rlmM(:)),(lenV-mu).^2);
    featureS.rlv = sum(jMinusMuPij(:));
end

% Run Entropy
if flagS.re
    runSum = sum(rlmM(:));
    featureS.re = -sum(rlmM(:)/runSum .* log2(rlmM(:)/runSum + eps));
end

