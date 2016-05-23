function featureS = cooccurToScalarFeatures(cooccurM, flagS)
% function featureS = cooccurToScalarFeatures(cooccurM, flagS)
%
% INPUT:  cooccurM of size (nL*nL) x numPatches
%         flagS is a structure with feature names as its fields.
%         The values represent flags to calculate (or not) that particular feature.
%         EXAMPLE:
%         ** For global cooccurrence (i.e. all voxels included in the patch, 
%         cooccurM will be a column vector of size (nL*nL) x 1) 
%         ** For patch-wise calculation for an image with 100 voxels,
%         cooccurM will be of size (nL*nL) x 100
%         ** flagS.energy = 1;
%            flagS.entropy = 1;
%            flagS.contrast = 0;
% OUTPUT: featureS is a structure array with scalar texture features as its
%         fields. Each field's value is a vector containing the feature values 
%         for each column cooccurM
%           
% APA, 05/13/2016

nL = size(cooccurM,1).^0.5;

% Build levels vector for mu, sig
levRowV = repmat(1:nL,[1 nL]);
levColV = repmat(1:nL,[nL 1]);
levColV = levColV(:)';

% Build list of indices for px and contrast calculation
for n=0:nL-1
    % indices for p(x-y), contrast
    indCtrstV = false(nL*nL,1);
    indCtrst1V = 1:nL-n;
    indCtrst2V = 1+n:nL;
    indCtrstTmpV = indCtrst1V + (indCtrst2V-1)*nL;
    indCtrstTmpV = [indCtrstTmpV indCtrst2V + (indCtrst1V-1)*nL];
    indCtrstV(indCtrstTmpV) = 1;
    indCtrstC{n+1} = indCtrstV;
       
    % indices for px
    indPxV = false(nL*nL,1);
    indPxV(nL*n+1:nL*(n+1)) = true;
    indPxC{n+1} = indPxV;
        
end
for n=1:2*nL
    % indices for p(x+y)
    indPxPlusYv = false(nL*nL,1);
    indPxPlusYv(levRowV + levColV == n) = 1;
    indPxPlusYc{n} = indPxPlusYv;
end

% Calculate scalar texture for this offset
% Angular Second Moment (Energy = sqrt(ASM))
if flagS.energy
    featureS.energy = sum(cooccurM.^2);
end
% Entropy
if flagS.entropy
    featureS.entropy = -sum(cooccurM.*log2(cooccurM+1e-10));
end
% Contrast, inverse Difference Moment
featureS.contrast = 0;
featureS.invDiffMom = 0;
% Contrast, inverse Difference Moment
for n=0:nL-1
    % px
    px(n+1,:) = sum(cooccurM(indPxC{n+1},:),1);
    % p(x-y)
    pXminusY(n+1,:) = sum(cooccurM(indCtrstC{n+1},:),1);
    % Contrast
    if flagS.contrast
        featureS.contrast = featureS.contrast + ...
            sum(n^2*cooccurM(indCtrstC{n+1},:));
    end
    % inv diff moment
    if flagS.invDiffMoment
        featureS.invDiffMom = featureS.invDiffMom + ...
            sum((1/(1+n^2))*cooccurM(indCtrstC{n+1},:));
    end
end
featureS.sumAvg = 0;
for n=1:2*nL
    % p(x+y)
    pXplusY(n,:) = sum(cooccurM(indPxPlusYc{n},:),1);
    % Sum Average
    if flagS.sumAvg
        featureS.sumAvg = featureS.sumAvg + n*pXplusY(n,:);
    end
end

% weighted pixel average (mu), weighted pixel variance (sig)
mu = (1:nL) * px;
sig = bsxfun(@minus,(1:nL)',mu);
sig = sum(sig .*sig .* px, 1);

% Correlation
if flagS.corr
    levIMinusMu = bsxfun(@minus,levRowV',mu);
    levJMinusMu = bsxfun(@minus,levColV',mu);
    %sig = sum(levIMinusMu.^2 .* cooccurPatchM,1);
    featureS.corr = sum(levIMinusMu .* levJMinusMu  .* cooccurM, 1) ...
        ./ (sig + 1e-10); % sig.^2 to match ITK results (ITK bug)
end

% Cluster Shade
if flagS.clustShade
    levIMinusMu = bsxfun(@minus,levRowV',mu);
    levJMinusMu = bsxfun(@minus,levColV',mu);
    clstrV = levIMinusMu + levJMinusMu;
    featureS.clustShade = sum(clstrV.*clstrV.*clstrV .* cooccurM, 1);
end
% Cluster Prominence
if flagS.clustProm
    levIMinusMu = bsxfun(@minus,levRowV',mu);
    levJMinusMu = bsxfun(@minus,levColV',mu);
    clstrV = levIMinusMu + levJMinusMu;
    featureS.clustPromin = sum(clstrV.*clstrV.*clstrV.*clstrV .* cooccurM, 1);
end

% Haralick Correlation
if flagS.haralickCorr
    % muX = mean(px,1);
    muX = 1/nL;
    %sigX = bsxfun(@minus,px,muX);
    sigX = px - muX;
    sigX = sum(sigX .*sigX, 1)/(nL);
    
    %              % Knuth method for mean and standard deviation (like ITK)
    %              muX = px(1,:);
    %              muPrevX = muX;
    %              sigX = muX*0;
    %              for col = 2:size(px,1)
    %                  muX = muPrevX + (px(col,:) - muPrevX)/col;
    %                  sigX = sigX + (px(col,:)-muX).*(px(col,:)-muPrevX);
    %                  muPrevX = muX;
    %              end
    %              sigX = sigX/nL;
    
    featureS.haralickCorr = (levRowV .* levColV * cooccurM - ...
        muX .* muX) ./ (sigX + eps);   % (levRowV-1) .* (levColV-1) to match ITK? Bug?
    
end


