function [energy3M,entropy3M,sumAvg3M,corr3M,invDiffMom3M,contrast3M,...
    clustShade3M,clustPromin3M,haralCorr3M] = textureByPatch(scanArray3M, nL, ...
    patchSizeV, offsetsM, flagv, hWait, minIntensity,maxIntensity,binWidth,separateDirnFlag)
% function [energy3M,entropy3M,sumAvg3M,corr3M,invDiffMom3M,contrast3M,...
%     clustShade3M,clustPromin3M,haralCorr3M] = textureByPatch(scanArray3M, nL, ...
%     patchSizeV, offsetsM, flagv, hWait, minIntensity,maxIntensity,separateDirnFlag)
%
% Patch-wise texture calculation.
%
% INPUTS:
%  scanArray3M: quantized scanArray. If not quantized, minIntensity and
%   maxIntensity must be input for quantization.
%  nL: number of gray levels.
%  patchSizeV: 3-element vectory specifying patch radius in voxel units.
%  offsetsM: nx3 matrix where each row represents the directional offset.
%   flagv: vactor specifying flags for calculation of specific features.
%  ones(1,9) to extract all features.
%  minIntensity: Minimum intensity for quantization (required only if
%   the input scanArray3M is not already quantized).
%  maxIntensity: Maximum intensity for quantization (required only if
%   the input scanArray3M is not already quantized).
%  separateDirnFlag: If 1 then features for each directional offset are
%   calculated. If 0 then features are averaged over all directional
%   offsets.
%
% APA, 09/09/2015

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
% calcIndM = q > 0;


% % Grid resolution
slcWindow = 2 * patchSizeV(3) + 1;
rowWindow = 2 * patchSizeV(1) + 1;
colWindow = 2 * patchSizeV(2) + 1;

% Build distance matrices
numColsPad = floor(colWindow/2);
numRowsPad = floor(rowWindow/2);
numSlcsPad = floor(slcWindow/2);

% Get number of voxels per slice
[numRows, numCols, numSlices] = size(scanArray3M);
% [numRows, numCols, numSlices] = size(q);
numVoxels = numRows*numCols;

% Quantize the image

% minQ = min(scanArray3M(:));
% maxQ = max(scanArray3M(:));
% dq = (maxQ-minQ)/nL/4;
% levels = linspace(minQ,maxQ,nL);
% levels = linspace(dq,maxQ-dq,nL);
% q2 = imquantize(scanArray3M, levels);
%levels = multithresh(scanArray3M, nL);
%q3 = imquantize(scanArray3M, levels);

% q = imquantize_cerr(scanArray3M,nL);

% Pad q, so that sliding window works also for the edge voxels
%scanArrayTmp3M = padarray(scanArray3M,[numRowsPad numColsPad
%numSlcsPad],NaN,'both'); % aa commented
%q = padarray(q,[numRowsPad numColsPad numSlcsPad],NaN,'both');

% Quantize the image
% if exist('minIntensity','var') && exist('maxIntensity','var')
%     q = imquantize_cerr(scanArray3M,nL,minIntensity,maxIntensity);
% else
%     q = imquantize_cerr(scanArray3M,nL);
% end

if ~exist('minIntensity','var')
    minIntensity = [];
end
if ~exist('maxIntensity','var')
    maxIntensity = [];
end
if exist('binWidth','var') && ~isempty(binWidth)
    q = imquantize_cerr(scanArray3M,nL,minIntensity,maxIntensity,binWidth);
elseif exist('nL','var') && ~isempty(nL)
    q = imquantize_cerr(scanArray3M,nL,minIntensity,maxIntensity);
else
    error('Number of quantization levels or binWidth required')
end
nL = max(q(:));

clear scanArray3M

% Pad q, so that sliding window works also for the edge voxels
%scanArrayTmp3M = padarray(scanArray3M,[numRowsPad numColsPad
%numSlcsPad],NaN,'both'); % aa commented
if exist('padarray.m','file')
    q = padarray(q,[numRowsPad numColsPad numSlcsPad],NaN,'both');
else
    q = padarray_oct(q,[numRowsPad numColsPad numSlcsPad],NaN,'both');
end

%nL = 16;
% if any(isnan(q)) % aa commented
%     nL = nL-1; % aa commented
% end % aa commented
%q = imquantize_cerr(scanArrayTmp3M,nL); % aa commented
%clear scanArrayTmp3M; % aa commented
%qmax = max(q(:));
nanFlag = 0; % the quantized image is always padded with NaN. Hence, always,
             % nanFlag = 1.
if any(isnan(q(:)))
    nanFlag = 1;
    q(isnan(q)) = nL+1;
end
lq = nL + 1;

% qs=sort(unique(q));
% lq=length(qs);
% for k = 1:length(qs)
% 	q(q==qs(k)) = k;
% end

q = uint16(q); % q is the quantized image
%numSlcsWithPadding = size(q,3);

% Create indices for 2D blocks
[m,n,~] = size(q);
m = uint32(m);
n = uint32(n);
colWindow = uint32(colWindow);
rowWindow = uint32(rowWindow);
slcWindow = uint32(slcWindow);

% Index calculation adapted from 
% http://stackoverflow.com/questions/25449279/efficient-implementation-of-im2col-and-col2im

%// Start indices for each block
start_ind = reshape(bsxfun(@plus,[1:m-rowWindow+1]',[0:n-colWindow]*m),[],1); %//'

%// Row indices
lin_row = permute(bsxfun(@plus,start_ind,[0:rowWindow-1])',[1 3 2]);  %//'

%// Get linear indices based on row and col indices and get desired output
% imTmpM = A(reshape(bsxfun(@plus,lin_row,[0:ncols-1]*m),nrows*ncols,[]));
indM = reshape(bsxfun(@plus,lin_row,(0:colWindow-1)*m),rowWindow*colWindow,[]);

% Directional offsets
numOffsets = size(offsetsM,1);

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
numElems = nL*nL;
indCtrstM = false(nL,numElems);
indPxM = false(nL,numElems);
indPxPlusYm = false(nL,numElems);
for n = 0:nL-1
    % indices for p(x-y), contrast
    indCtrstV = false(lq*lq,1);
    indCtrst1V = 1:lq-n;
    indCtrst2V = 1+n:lq;
    indCtrstTmpV = indCtrst1V + (indCtrst2V-1)*lq;
    indCtrstTmpV = [indCtrstTmpV indCtrst2V + (indCtrst1V-1)*lq];
    indCtrstV(indCtrstTmpV) = 1;
    indCtrstV(nanIndV) = [];
    indCtrstM(n+1,:) = indCtrstV;
       
    % indices for px
    indPxV = false(lq*lq,1);
    indPxV(lq*n+1:lq*(n+1)) = true;
    indPxV(nanIndV) = [];
    indPxM(n+1,:) = indPxV;
        
end
for n=1:2*nL
    % indices for p(x+y)
    indPxPlusYv = false(lq*lq,1);
    indPxPlusYv(levRowV + levColV == n) = 1;
    indPxPlusYv(nanIndV) = [];
    indPxPlusYm(n,:) = indPxPlusYv;
end


% Build linear indices column/row-wise for Symmetry
indRowV = zeros(1,lq*lq,'uint16');
for i=uint16(1:lq)
    indRowV((i-1)*lq+1:(i-1)*lq+lq) = i:lq:lq*lq;
end

% Filter out NaN levels
levRowV(nanIndV) = [];
levColV(nanIndV) = [];

dim = 1;
if separateDirnFlag   
    dim = numOffsets;
end

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
    energy3M = zeros([numRows, numCols, numSlices, dim],'single');
end
if flagv(2)
    entropy3M = zeros([numRows, numCols, numSlices, dim],'single');
end
if flagv(3)
    sumAvg3M = zeros([numRows, numCols, numSlices, dim],'single');
end
if flagv(4)
    corr3M = zeros([numRows, numCols, numSlices, dim],'single');
end
if flagv(5)
    invDiffMom3M = zeros([numRows, numCols, numSlices, dim],'single');
end
if flagv(6)
    contrast3M = zeros([numRows, numCols, numSlices, dim],'single');
end
if flagv(7)
    clustShade3M = zeros([numRows, numCols, numSlices, dim],'single');
end
if flagv(8)
    clustPromin3M = zeros([numRows, numCols, numSlices, dim],'single');
end
if flagv(9)
    haralCorr3M = zeros([numRows, numCols, numSlices, dim],'single');
end

tic
% Iterate over slices. compute cooccurance for all patches per slice
for slcNum = 1:numSlices
    
    disp(['--- Texture Calculation for Slice # ', num2str(slcNum), ' ----']) 
    if flagv(1), energyV = zeros(dim,numVoxels,'single'); end
    if flagv(2), entropyV = zeros(dim,numVoxels,'single'); end
    if flagv(3), sumAvgV = zeros(dim,numVoxels,'single'); end
    if flagv(4), corrV = zeros(dim,numVoxels,'single'); end
    if flagv(5), invDiffMomV = zeros(dim,numVoxels,'single'); end
    if flagv(6), contrastV = zeros(dim,numVoxels,'single'); end
    if flagv(7), clustShadeV = zeros(dim,numVoxels,'single'); end
    if flagv(8), clustProminV = zeros(dim,numVoxels,'single'); end    
    if flagv(9), haralCorrV = zeros(dim,numVoxels,'single'); end    
    
    calcSlcIndV = calcIndM(:,:,slcNum);
    calcSlcIndV = calcSlcIndV(:);
    numCalcVoxs = sum(calcSlcIndV);
    %indSlcM = indM(:,calcSlcIndV); %moved to offset loop
    % List of Voxel numbers
    voxelNumsV = uint32(0:lq*lq:lq*lq*(numCalcVoxs-1));   
    for off = 1:numOffsets
        % Get voxels for this slice 
        indSlcM = indM(:,calcSlcIndV);
        %cooccurPatchM = zeros(lq*lq*numCalcVoxs,1,'double');
        offset = offsetsM(off,:);        
        % Choose correct neighbors for the selected offset. i.e. the
        % correct rows from indSlcM
        indNoNeighborV = [];
        if offset(1) == 1
            indNoNeighborV = [indNoNeighborV 1:rowWindow:rowWindow*colWindow];
        elseif offset(1) == -1
            indNoNeighborV = [indNoNeighborV rowWindow:rowWindow:rowWindow*colWindow];
        end
        if offset(2) == 1
            indNoNeighborV = [indNoNeighborV 1:colWindow];
        elseif offset(2) == -1
            indNoNeighborV = [indNoNeighborV rowWindow*colWindow:-1:(rowWindow*colWindow-colWindow)+1];
        end        
        indSlcM(indNoNeighborV,:) = [];
        
        % index for various scalar features
        featDim = min(dim,off);
        
        slcNumV = slcNum:slcNum+slcWindow-1; % slices within the patch
        C = cell(length(slcNumV),1);
        for iSlc = 1:length(slcNumV)
            slc = slcNumV(iSlc);
            if slc-slcNum+offset(3) >= slcWindow
                continue;
            end
            slc1M = uint16(q(numRowsPad+(1:numRows),numColsPad+(1:numCols),slc));
            slc2M = uint16(q(:,:,slc+offset(3)));
            slc2M = circshift(slc2M,offset(1:2));
            slc2M(numRowsPad+(1:numRows),numColsPad+(1:numCols)) = ...
                slc2M(numRowsPad+(1:numRows),numColsPad+(1:numCols)) + (slc1M-1)*lq;            
%             for colNum = 1:numCalcVoxs
%                 cooccurPatchTmpM(:,colNum) = ...
%                     accumarray(slc2M(indSlcM(:,colNum)),1,[lq*lq,1]);
%             end
            slc2M = uint32(slc2M(indSlcM));
            slc2M = bsxfun(@plus,slc2M,voxelNumsV); 
            cooccurSlcM = accumarray(slc2M(:) ...
                ,1, [lq*lq*numCalcVoxs,1],[],...
                [],true); % patch-wise cooccurance
            indToAddV = find(cooccurSlcM > 0);            
            C{iSlc} = [indToAddV,cooccurSlcM(indToAddV)]';
            %cooccurPatchM(indToAddV) = cooccurPatchM(indToAddV) + cooccurSlcM(indToAddV);
        end
        IJV = cell2mat(C);
        cooccurPatchM = sparse(IJV(1,:),IJV(1,:).^0,IJV(2,:),lq*lq*numCalcVoxs,1);
        cooccurPatchM = reshape(cooccurPatchM,lq*lq,numCalcVoxs);
        cooccurPatchM = cooccurPatchM + cooccurPatchM(indRowV,:); % for symmetry
        cooccurPatchM(nanIndV,:) = [];
        %cooccurPatchM = cooccurPatchM(~nanIndV,:);
        cooccurPatchM = bsxfun(@rdivide,cooccurPatchM,sum(cooccurPatchM)+1e-5);
        cooccurPatchM = full(cooccurPatchM);
        % Calculate scalar texture for this offset
        % Angular Second Moment (Energy)
        if flagv(1)
            energyV(featDim,calcSlcIndV) = energyV(featDim,calcSlcIndV) + ...
                sum(cooccurPatchM .* cooccurPatchM); % cooccurPatchM.^2
        end
        % Entropy
        if flagv(2)
            entropyV(featDim,calcSlcIndV) = entropyV(featDim,calcSlcIndV) - ...
                sum(cooccurPatchM.*log2(cooccurPatchM+1e-10));
        end
        px = indPxM * cooccurPatchM;
        
        % Sum Average
        if flagv(3)
            sumAvgV(featDim,calcSlcIndV) = sumAvgV(featDim,calcSlcIndV) + ...
                (1:2*nL) * indPxPlusYm * cooccurPatchM;
        end
        
        % inv diff moment
        if flagv(5)
        invDiffMomV(featDim,calcSlcIndV) = invDiffMomV(featDim,calcSlcIndV) + ...
            1./(1+(0:nL-1).^2) * indCtrstM * cooccurPatchM;
        end        
       
        % Contrast
        if flagv(6)
            contrastV(featDim,calcSlcIndV) = contrastV(featDim,calcSlcIndV) + ...
                (0:nL-1).^2 * indCtrstM * cooccurPatchM;
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
            corrV(featDim,calcSlcIndV) = corrV(featDim,calcSlcIndV) + ...
                sum(levIMinusMu .* levJMinusMu  .* cooccurPatchM, 1) ...
                ./ (sig + 1e-10); % sig.^2 to match ITK results (ITK bug)            
        end

        % Cluster Shade
        if flagv(7)
            clstrV = levIMinusMu + levJMinusMu;
            clustShadeV(featDim,calcSlcIndV) = clustShadeV(featDim,calcSlcIndV) + ...
                sum(clstrV.*clstrV.*clstrV .* cooccurPatchM, 1);
        end
        % Cluster Prominence
        if flagv(8)
            clstrV = levIMinusMu + levJMinusMu;            
            clustProminV(featDim,calcSlcIndV) = clustProminV(featDim,calcSlcIndV) + ...
                sum(clstrV.*clstrV.*clstrV.*clstrV .* cooccurPatchM, 1);
        end
        
        % Haralick Correlation
         if flagv(9)             
             % muX = mean(px,1);
             muX = 1/nL;
             % sigX = bsxfun(@minus,px,muX);
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
             
             haralCorrV(featDim,calcSlcIndV) = haralCorrV(featDim,calcSlcIndV) + ...
                 (levRowV .* levColV * cooccurPatchM - ...
                 muX .* muX) ./ (sigX + eps);   % (levRowV-1) .* (levColV-1) to match ITK? Bug?       
             
         end        
    end
    
    % Average texture from all directions
    if flagv(1)
        energyV = energyV / numOffsets;
        energy3M(:,:,slcNum,:) = reshape(energyV',[numRows, numCols, 1, dim]);
    end
    if flagv(2)
        entropyV = entropyV / numOffsets;
        entropy3M(:,:,slcNum,:) = reshape(entropyV',[numRows, numCols, 1, dim]);
    end
    if flagv(3)
        sumAvgV = sumAvgV / numOffsets;
        sumAvg3M(:,:,slcNum,:) = reshape(sumAvgV',[numRows, numCols, 1, dim]);
    end
    if flagv(4)
        corrV = corrV / numOffsets;
        corr3M(:,:,slcNum,:) = reshape(corrV',[numRows, numCols, 1, dim]);
    end
    if flagv(5)
        invDiffMomV = invDiffMomV / numOffsets;
        invDiffMom3M(:,:,slcNum,:) = reshape(invDiffMomV',[numRows, numCols, 1, dim]);
    end
    if flagv(6)
        contrastV = contrastV / numOffsets;
        contrast3M(:,:,slcNum,:) = reshape(contrastV',[numRows, numCols, 1, dim]);
    end
    if flagv(7)
        clustShadeV = clustShadeV / numOffsets;
        clustShade3M(:,:,slcNum,:) = reshape(clustShadeV',[numRows, numCols, 1, dim]);
    end
    if flagv(8)
        clustProminV = clustProminV / numOffsets;
        clustPromin3M(:,:,slcNum,:) = reshape(clustProminV',[numRows, numCols, 1, dim]);
    end
    if flagv(9)
        haralCorrV = haralCorrV / numOffsets;
        haralCorr3M(:,:,slcNum,:) = reshape(haralCorrV',[numRows, numCols, 1, dim]);                
    end
    
    if waitbarFlag
        set(hWait, 'Vertices', [[0 0 slcNum/numSlices slcNum/numSlices]' [0 1 1 0]']);
        drawnow;
    end 
    
end
toc

