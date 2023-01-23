function [energy3M,entropy3M,sumAvg3M,corr3M,invDiffMom3M,contrast3M,...
    clustShade3M,clustPromin3M,haralCorr3M] = textureByPatchAllOffsFromCtr(scanArray3M, nL, ...
    patchSizeV, flagv, hWait, minIntensity, maxIntensity)
% function [energy3M,entropy3M,sumAvg3M,corr3M,invDiffMom3M,contrast3M,...
%     clustShade3M,clustPromin3M,haralCorr3M] = textureByPatchAllOffsFromCtr(scanArray3M, nL, ...
%     patchSizeV, flagv, hWait, minIntensity, maxIntensity)
%
% This function calculates GLCM texture from patches w.r.t. their centers.
%
% INPUTS:
% scanArray3M - Scan matrix with NaN values for voxels that are not to be
% included in texture calculation.
% nL - Number of gray levels
% patchSizeV - 3-element vector for the patch radius. For example, [3 3 0]
% flagv - 9-element vector of booleans to toggle calculation of texture features.
% hWait - (optional) waitbar handle. Use NaN to turn off waitbar.
% minIntensity - (optional) minimum intensity for discretization.
% maxIntensity - (optional) maximum intensity for discretization.
%
% Example:
% scan3M(~mask3M) = NaN;
% flagV = zeros(1,9);
% flagV(2) = 1; % entropy only
% nL = 64;
% patchSizeV = [3 3 0];
% [~,entropy3M] = textureByPatchAllOffsFromCtr(scan3M, nL, ...
%     patchSizeV, offsetsM, flagV);
%
% APA, 11/07/2018

% Generate flags
if ~exist('flagv','var')
    flagv = ones(1,9);
elseif exist('flagv','var') && isempty(flagv)
    flagv = ones(1,9);
end

% Flag to draw waitbar
waitbarFlag = 0;
if exist('hWait','var') && ishandle(hWait)
    waitbarFlag = 1;
end

% Get indices of non-NaN voxels
calcIndM = ~isnan(scanArray3M);

slcWindow = 2 * patchSizeV(3) + 1;
rowWindow = 2 * patchSizeV(1) + 1;
colWindow = 2 * patchSizeV(2) + 1;

% Build distance matrices
numColsPad = floor(colWindow/2);
numRowsPad = floor(rowWindow/2);
numSlcsPad = floor(slcWindow/2);

% Get number of voxels per slice
[numRows, numCols, numSlices] = size(scanArray3M);
numVoxels = numRows*numCols;

% Quantize the image
if exist('minIntensity','var') && exist('maxIntensity','var')
    q = imquantize_cerr(scanArray3M,nL,minIntensity,maxIntensity);
else
    q = imquantize_cerr(scanArray3M,nL);
end

% Pad q, so that sliding window works also for the edge voxels
%scanArrayTmp3M = padarray(scanArray3M,[numRowsPad numColsPad
%numSlcsPad],NaN,'both'); % aa commented
if exist('padarray.m','file')
    q = padarray(q,[numRowsPad numColsPad numSlcsPad],NaN,'both');
else
    q = padarray_oct(q,[numRowsPad numColsPad numSlcsPad],NaN,'both');
end

nanFlag = 0; % the quantized image is always padded with NaN. Hence, always,
% nanFlag = 1.
if any(isnan(q(:)))
    nanFlag = 1;
    q(isnan(q)) = nL+1;
end
lq = nL + 1;

q = uint16(q); % q is the quantized image

% Create indices for 2D blocks
[m,n,~] = size(q);
m = uint32(m);
n = uint32(n);
colWindow = uint32(colWindow);
rowWindow = uint32(rowWindow);
slcWindow = uint32(slcWindow);

% Index calculation adapted from
% http://stackoverflow.com/questions/25449279/efficient-implementation-of-im2col-and-col2im

% Start indices for each block
start_ind = reshape(bsxfun(@plus,[1:m-rowWindow+1]',[0:n-colWindow]*m),[],1);

% Row indices
lin_row = permute(bsxfun(@plus,start_ind,[0:rowWindow-1])',[1 3 2]);

% Get linear indices based on row and col indices and get desired output
indM = reshape(bsxfun(@plus,lin_row,(0:colWindow-1)*m),rowWindow*colWindow,[]);

% Indices of last level to filter out
nanIndV = false([lq*lq,1]);
if nanFlag
    nanIndV([lq:lq:lq*lq-lq, lq*lq-lq:lq*lq]) = true;
end

% Build levels vector for mu, sig
levRowV = repmat(1:lq,[1 lq]);
levColV = repmat(1:lq,[lq 1]);
levColV = levColV(:)';

% Build list of indices for px and contrast calculation
numElems = nL*nL; % APA 7/13
indCtrstM = false(nL,numElems); % APA 7/13
indPxM = false(nL,numElems); % APA 7/13
indPxPlusYm = false(nL,numElems); % APA 7/13
for n=0:nL-1
    % indices for p(x-y), contrast
    indCtrstV = false(lq*lq,1);
    indCtrst1V = 1:lq-n;
    indCtrst2V = 1+n:lq;
    indCtrstTmpV = indCtrst1V + (indCtrst2V-1)*lq;
    indCtrstTmpV = [indCtrstTmpV indCtrst2V + (indCtrst1V-1)*lq];
    indCtrstV(indCtrstTmpV) = 1;
    indCtrstV(nanIndV) = [];
    % indCtrstC{n+1} = indCtrstV;
    indCtrstM(n+1,:) = indCtrstV;
    
    % indices for px
    indPxV = false(lq*lq,1);
    indPxV(lq*n+1:lq*(n+1)) = true;
    indPxV(nanIndV) = [];
    % indPxC{n+1} = indPxV;
    indPxM(n+1,:) = indPxV;
    
end
for n=1:2*nL
    % indices for p(x+y)
    indPxPlusYv = false(lq*lq,1);
    indPxPlusYv(levRowV + levColV == n) = 1;
    indPxPlusYv(nanIndV) = [];
    % indPxPlusYc{n} = indPxPlusYv;
    indPxPlusYm(n,:) = indPxPlusYv;
end

% Build linear indices column/row-wise for Symmetry
indRowV = zeros(1,lq*lq);
for i=1:lq
    indRowV((i-1)*lq+1:(i-1)*lq+lq) = i:lq:lq*lq;
end

% Filter out NaN levels
levRowV(nanIndV) = [];
levColV(nanIndV) = [];

% Initialize
energy3M = [];
entropy3M = [];
sumAvg3M = [];
corr3M = [];
invDiffMom3M = [];
contrast3M = [];
clustShade3M = [];
clustPromin3M = [];
haralCorr3M = [];
if flagv(1)
    energy3M = zeros([numRows, numCols, numSlices],'single');
end
if flagv(2)
    entropy3M = zeros([numRows, numCols, numSlices],'single');
end
if flagv(3)
    sumAvg3M = zeros([numRows, numCols, numSlices],'single');
end
if flagv(4)
    corr3M = zeros([numRows, numCols, numSlices],'single');
end
if flagv(5)
    invDiffMom3M = zeros([numRows, numCols, numSlices],'single');
end
if flagv(6)
    contrast3M = zeros([numRows, numCols, numSlices],'single');
end
if flagv(7)
    clustShade3M = zeros([numRows, numCols, numSlices],'single');
end
if flagv(8)
    clustPromin3M = zeros([numRows, numCols, numSlices],'single');
end
if flagv(9)
    haralCorr3M = zeros([numRows, numCols, numSlices],'single');
end

tic
% Iterate over slices. compute cooccurance for all patches per slice
for slcNum = 1:numSlices
    disp(['--- Texture Calculation for Slice # ', num2str(slcNum), ' ----'])
    if flagv(1), energyV = zeros(1,numVoxels,'single'); end
    if flagv(2), entropyV = zeros(1,numVoxels,'single'); end
    if flagv(3), sumAvgV = zeros(1,numVoxels,'single'); end
    if flagv(4), corrV = zeros(1,numVoxels,'single'); end
    if flagv(5), invDiffMomV = zeros(1,numVoxels,'single'); end
    if flagv(6), contrastV = zeros(1,numVoxels,'single'); end
    if flagv(7), clustShadeV = zeros(1,numVoxels,'single'); end
    if flagv(8), clustProminV = zeros(1,numVoxels,'single'); end
    if flagv(9), haralCorrV = zeros(1,numVoxels,'single'); end
    
    calcSlcIndV = calcIndM(:,:,slcNum);
    calcSlcIndV = calcSlcIndV(:);
    numCalcVoxs = sum(calcSlcIndV);
    %indSlcM = indM(:,calcSlcIndV);
    indSlcM = indM(:,calcSlcIndV);
    indCurrVox = ceil(size(indM,1)/2);
    indCurrVoxV = indSlcM(indCurrVox,:);
    %slcM = uint32(q(numRowsPad+(1:numRows),numColsPad+(1:numCols),slcNum));
    % List of Voxel numbers
    voxelNumsV = uint32(0:lq*lq:lq*lq*(numCalcVoxs-1));
    slcM = uint32(q(:,:,slcNum));
    voxelValsV = slcM(indCurrVoxV);
    slc2M = slcM(indSlcM);
    slc2M = bsxfun(@plus, slc2M, (voxelValsV-1)*lq + voxelNumsV);
    %slc2M = bsxfun(@plus,slc2M,voxelNumsV);
    cooccurPatchM = accumarray(slc2M(:) ...
        ,1, [lq*lq*numCalcVoxs,1],[],...
        [],true); % patch-wise cooccurance
    cooccurPatchM = reshape(cooccurPatchM,lq*lq,numCalcVoxs);
    cooccurPatchM = cooccurPatchM + cooccurPatchM(indRowV,:); % for symmetry
    cooccurPatchM(nanIndV,:) = [];
    cooccurPatchM = bsxfun(@rdivide,cooccurPatchM,sum(cooccurPatchM)+1e-5);
    cooccurPatchM = full(cooccurPatchM);
    
    
    % Angular Second Moment (Energy)
    if flagv(1)
        energyV(calcSlcIndV) = energyV(calcSlcIndV) + sum(cooccurPatchM.^2);
    end
    % Entropy
    if flagv(2)
        entropyV(calcSlcIndV) = entropyV(calcSlcIndV) - ...
            sum(cooccurPatchM.*log2(cooccurPatchM+1e-10));
    end
    
    %     % Contrast, inverse Difference Moment, sum avg
    px = indPxM * cooccurPatchM;
    if flagv(3) || flagv(5) || flagv(6)
        %pXminusY = indCtrstM * cooccurPatchM;
        %pXplusY = indPxPlusYm * cooccurPatchM;
        contrastV(calcSlcIndV) = contrastV(calcSlcIndV) + ...
            (0:nL-1).^2 * indCtrstM * cooccurPatchM;
        invDiffMomV(calcSlcIndV) = invDiffMomV(calcSlcIndV) + ...
            1./(1+(0:nL-1).^2) * indCtrstM * cooccurPatchM;
        sumAvgV(calcSlcIndV) = sumAvgV(calcSlcIndV) + ...
            (1:2*nL) * indPxPlusYm * cooccurPatchM;
    end
    
    % weighted pixel average (mu), weighted pixel variance (sig)
    mu = (1:nL) * px;
    sig = bsxfun(@minus,(1:nL)',mu);
    sig = sum(sig .*sig .* px, 1);
    
    if flagv(4) || flagv(7) || flagv(8)
        levIMinusMu = bsxfun(@minus,levRowV',mu);
        levJMinusMu = bsxfun(@minus,levColV',mu);
    end
    
    % Correlation
    if flagv(4)
        corrV(calcSlcIndV) = corrV(calcSlcIndV) + ...
            sum(levIMinusMu .* levJMinusMu  .* cooccurPatchM, 1) ...
            ./ (sig + 1e-10); % sig.^2 to match ITK results (ITK bug)
    end
    
    % Cluster Shade
    if flagv(7)
        clstrV = levIMinusMu + levJMinusMu;
        clustShadeV(calcSlcIndV) = clustShadeV(calcSlcIndV) + ...
            sum(clstrV.*clstrV.*clstrV .* cooccurPatchM, 1);
    end
    % Cluster Prominence
    if flagv(8)
        clstrV = levIMinusMu + levJMinusMu;
        clustProminV(calcSlcIndV) = clustProminV(calcSlcIndV) + ...
            sum(clstrV.*clstrV.*clstrV.*clstrV .* cooccurPatchM, 1);
    end
    
    % Haralick Correlation
    if flagv(9)
        % muX = mean(px,1);
        muX = 1/nL;
        % sigX = bsxfun(@minus,px,muX);
        sigX = px - muX;
        sigX = sum(sigX .*sigX, 1)/(nL);
        
        % % Knuth method for mean and standard deviation (like ITK)
        %              muX = px(1,:);
        %              muPrevX = muX;
        %              sigX = muX*0;
        %              for col = 2:size(px,1)
        %                  muX = muPrevX + (px(col,:) - muPrevX)/col;
        %                  sigX = sigX + (px(col,:)-muX).*(px(col,:)-muPrevX);
        %                  muPrevX = muX;
        %              end
        %              sigX = sigX/nL;
        
        haralCorrV(calcSlcIndV) = haralCorrV(calcSlcIndV) + ...
            (levRowV .* levColV * cooccurPatchM - ...
            muX .* muX) ./ (sigX + eps);   % (levRowV-1) .* (levColV-1) to match ITK? Bug?
        
    end
    
    if flagv(1)
        energy3M(:,:,slcNum) = reshape(energyV(:),[numRows, numCols]);
    end
    if flagv(2)
        entropy3M(:,:,slcNum) = reshape(entropyV(:),[numRows, numCols]);
    end
    if flagv(3)
        sumAvg3M(:,:,slcNum) = reshape(sumAvgV(:),[numRows, numCols]);
    end
    if flagv(4)
        corr3M(:,:,slcNum) = reshape(corrV(:),[numRows, numCols]);
    end
    if flagv(5)
        invDiffMom3M(:,:,slcNum) = reshape(invDiffMomV(:),[numRows, numCols]);
    end
    if flagv(6)
        contrast3M(:,:,slcNum) = reshape(contrastV(:),[numRows, numCols]);
    end
    if flagv(7)
        clustShade3M(:,:,slcNum) = reshape(clustShadeV(:),[numRows, numCols]);
    end
    if flagv(8)
        clustPromin3M(:,:,slcNum) = reshape(clustProminV(:),[numRows, numCols]);
    end
    if flagv(9)
        haralCorr3M(:,:,slcNum) = reshape(haralCorrV(:),[numRows, numCols]);
    end
    
    if waitbarFlag
        set(hWait, 'Vertices', [[0 0 slcNum/numSlices slcNum/numSlices]' [0 1 1 0]']);
        drawnow;
    end
end
toc

