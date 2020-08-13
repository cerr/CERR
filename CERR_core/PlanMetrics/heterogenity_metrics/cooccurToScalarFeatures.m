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
%            flagS.jointEntropy = 1;
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
    %indCtrstV = false(nL*nL,1); %apa
    indCtrst1V = 1:nL-n;
    indCtrst2V = 1+n:nL;
    indCtrstTmpV = indCtrst1V + (indCtrst2V-1)*nL;
    indCtrstTmpV = [indCtrstTmpV indCtrst2V + (indCtrst1V-1)*nL];
    %indCtrstV(indCtrstTmpV) = 1; %apa
    %indCtrstC{n+1} = indCtrstV; %apa
    indCtrstC{n+1} = unique(indCtrstTmpV); %apa new
       
    % indices for px
    %indPxV = false(nL*nL,1); %apa
    %indPxV(nL*n+1:nL*(n+1)) = true; %apa
    %indPxC{n+1} = indPxV; %apa
    indPxC{n+1} = nL*n+1:nL*(n+1); %apa new
        
end
for n=1:2*nL
    % indices for p(x+y), sum entropy, etc
    %indPxPlusYv = false(nL*nL,1); %apa
    %indPxPlusYv(levRowV + levColV == n) = 1; %apa
    %indPxPlusYc{n} = indPxPlusYv; %apa
    indPxPlusYc{n} = find(levRowV + levColV == n); %apa new
end

% Calculate scalar texture for this offset
% Angular Second Moment (Energy = sqrt(ASM))
if flagS.energy
    featureS.energy = sum(cooccurM.^2);
end
% Joint Entropy
if flagS.jointEntropy
    featureS.jointEntropy = -sum(cooccurM.*log2(cooccurM+eps));
end
if flagS.jointMax
    featureS.jointMax = max(cooccurM,[],1);
end
if flagS.jointAvg
    featureS.jointAvg = sum(bsxfun(@times,cooccurM',levRowV),2)';
end
if flagS.jointVar
    xMinumMu = bsxfun(@minus,levRowV',featureS.jointAvg).^2;
    featureS.jointVar = sum(xMinumMu .* cooccurM,1);
end

% Number of cooccur matrices
numCooccurs = size(cooccurM,2);

% Contrast, inverse Difference Moment
featureS.contrast = zeros(1,numCooccurs);
featureS.invDiffMom = zeros(1,numCooccurs);
featureS.invDiffMomNorm = zeros(1,numCooccurs);
featureS.invDiff = zeros(1,numCooccurs);
featureS.invDiffNorm = zeros(1,numCooccurs);
featureS.invVar = zeros(1,numCooccurs);
featureS.dissimilarity = zeros(1,numCooccurs);
featureS.diffEntropy = zeros(1,numCooccurs);
featureS.diffVar = zeros(1,numCooccurs);
featureS.diffAvg = zeros(1,numCooccurs);
% Contrast, inverse Difference Moment
for n=0:nL-1
    % px
    px(n+1,:) = sum(cooccurM(indPxC{n+1},:),1);
    % p(x-y)
    pXminusY(n+1,:) = sum(cooccurM(indCtrstC{n+1},:),1);
    % p(x-y) log2(p(x-y))
    if any(indCtrstC{n+1})
        pXminusYlogPXminusY(n+1,:) = ...
            pXminusY(n+1,:) .* log2(eps + pXminusY(n+1,:));
    else
        pXminusYlogPXminusY(n+1,:) = 0;
    end
    % Difference Average
    if flagS.diffAvg
        featureS.diffAvg = featureS.diffAvg + n*pXminusY(n+1,:);
    end   
    
    % Contrast
    if flagS.contrast
        featureS.contrast = featureS.contrast + ...
            sum(n^2*cooccurM(indCtrstC{n+1},:));
    end
    % Dissimilarity (same as difference average)
    if flagS.dissimilarity || flagS.diffVar
        featureS.dissimilarity = featureS.dissimilarity + ...
            sum(n*cooccurM(indCtrstC{n+1},:));
    end    
    % inv diff moment
    if flagS.invDiffMoment
        featureS.invDiffMom = featureS.invDiffMom + ...
            sum((1/(1+n^2))*cooccurM(indCtrstC{n+1},:));
    end
    % inv diff moment normalized
    if flagS.invDiffMomNorm
        featureS.invDiffMomNorm = featureS.invDiffMomNorm + ...
            sum((1/(1+(n/nL)^2))*cooccurM(indCtrstC{n+1},:));      
    end
    % inv diff
    if flagS.invDiff
        featureS.invDiff = featureS.invDiff + ...
            sum((1/(1+n))*cooccurM(indCtrstC{n+1},:));      
    end    
    % inv diff normalized
    if flagS.invDiffNorm
        featureS.invDiffNorm = featureS.invDiffNorm + ...
            sum((1/(1+n/nL))*cooccurM(indCtrstC{n+1},:));        
    end    
    % inv variance
    if flagS.invVar && n > 0
        featureS.invVar = featureS.invVar + ...
            sum((1/n^2)*cooccurM(indCtrstC{n+1},:));
    end    
    % Difference Entropy
    if flagS.diffEntropy
        featureS.diffEntropy = featureS.diffEntropy - pXminusYlogPXminusY(n+1,:);
    end
    
end

for n=0:nL-1
    if flagS.diffVar
        featureS.diffVar = featureS.diffVar + (n - featureS.dissimilarity).^2 .* pXminusY(n+1,:) ;
    end    
end


% Sum Entropy, Sum Average, etc.
featureS.sumAvg = zeros(1,numCooccurs);
featureS.sumVar = zeros(1,numCooccurs);
featureS.sumEntropy = zeros(1,numCooccurs);
for n=1:2*nL
    % p(x+y)
    pXplusY(n,:) = sum(cooccurM(indPxPlusYc{n},:),1);
    % p(x+y) log2(p(x+y))
    if any(indPxPlusYc{n})
        pXplusYlogPXplusY(n,:) = ...
            pXplusY(n,:) .* log2(eps+pXplusY(n,:));
    else
        pXplusYlogPXplusY(n,:) = zeros(1,numCooccurs);
    end
    % Sum Average
    if flagS.sumAvg
        featureS.sumAvg = featureS.sumAvg + n*pXplusY(n,:);
    end
    % Sum Entropy
    if flagS.sumEntropy
        featureS.sumEntropy = featureS.sumEntropy - pXplusYlogPXplusY(n,:);
    end
end
for n=1:2*nL
    % Sum Variance
    if flagS.sumVar
        featureS.sumVar = featureS.sumVar + (n-featureS.sumAvg).^2 .* pXplusY(n,:);
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
        ./ (sig + eps); % sig.^2 to match ITK results (ITK bug)
end

% Cluster Tendency
if flagS.clustTendency
    levIMinusMu = bsxfun(@minus,levRowV',mu);
    levJMinusMu = bsxfun(@minus,levColV',mu);
    clstrV = levIMinusMu + levJMinusMu;
    featureS.clustTendency = sum(clstrV.*clstrV .* cooccurM, 1);
else
    featureS.clustTendency = NaN;
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

% Auto Correlation
if flagS.autoCorr
    featureS.autoCorr = sum(bsxfun(@times,cooccurM,levRowV' .* levColV'),1);    
else
    featureS.autoCorr = NaN;
end


% First measure of information correlation
if flagS.firstInfCorr
    HXY1 = -sum(cooccurM.*log2((px(levRowV,:)+eps)...
        .*(px(levColV,:)+eps)));
    HX = -sum(px.*log2(px+eps));
    featureS.firstInfCorr = (featureS.jointEntropy - HXY1) ./ HX;
end

% Second measure of information correlation
if flagS.secondInfCorr
    HXY2 = -sum(px(levRowV,:).*px(levColV,:)...
        .*log2((px(levRowV,:)+eps).*(px(levColV,:)+eps)));
    featureS.secondInfCorr = 1 - exp(-2*(HXY2 - featureS.jointEntropy));
    indZerosV = featureS.secondInfCorr <= 0;
    featureS.secondInfCorr(indZerosV) = 0;
    featureS.secondInfCorr = sqrt(featureS.secondInfCorr);
end


