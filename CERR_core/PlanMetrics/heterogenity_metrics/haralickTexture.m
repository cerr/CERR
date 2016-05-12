function [energyV,entropyV,sumAvgV,corrcorrV,invDiffMomV,contrastV,...
    clustShadeV,clustProminV] = haralickTexture(scanArray3M, nL, offsetsM, flagv, hWait)
% [energyV,entropyV,sumAvgV,corrcorrV,invDiffMomV,contrastV,...
%     clustShadeV,clustProminV] = haralickTexture(scanArray3M, nL, offsetsM, flagv, hWait)
%
% Haralick Texture.
%
% APA, 05/12/2016

% Generate flags
if ~exist('flagv','var')
    flagv = ones(1,8);
elseif exist('flagv','var') && isempty(flagv)
    flagv = ones(1,8);
end

% % Flag to draw waitbar
% waitbarFlag = 0;
% if exist('hWait','var') && ishandle(hWait)
%     waitbarFlag = 1;
% end

% Get indices of non-NaN voxels
calcIndM = ~isnan(scanArray3M);

% % Grid resolution
% deltaX = deltaXYZv(1);
% deltaY = deltaXYZv(2);
% deltaZ = deltaXYZv(3);
%
% % Get Block size to process
% slcWindow = floor(2*patchSizeV(3)/deltaZ);
% rowWindow = floor(2*patchSizeV(1)/deltaY);
% colWindow = floor(2*patchSizeV(2)/deltaX);
%
% % Make sure that the window is of odd size
% if mod(slcWindow,2) == 0
%     slcWindow = slcWindow + 1;
% end
% if mod(rowWindow,2) == 0
%     rowWindow = rowWindow + 1;
% end
% if mod(colWindow,2) == 0
%     colWindow = colWindow + 1;
% end

slcWindow = size(scanArray3M,3);
rowWindow = size(scanArray3M,1);
colWindow = size(scanArray3M,2);

% Build distance matrices
numColsPad = 1;
numRowsPad = 1;
numSlcsPad = 1;

% Get number of voxels per slice
[numRows, numCols, numSlices] = size(scanArray3M);
numVoxels = numRows*numCols;

minQ = min(scanArray3M(:));
maxQ = max(scanArray3M(:));
dq = (maxQ-minQ)/nL/4;
levels = linspace(minQ,maxQ,nL);
levels = linspace(dq,maxQ-dq,nL);
q1 = imquantize_cerr(scanArray3M,nL);
q2 = imquantize(scanArray3M, levels);
%levels = multithresh(scanArray3M, nL);
%q3 = imquantize(scanArray3M, levels);

% Pad doseArray2 so that sliding window works also for the edge voxels
%scanArrayTmp3M = padarray(scanArray3M,[numRowsPad numColsPad
%numSlcsPad],NaN,'both'); % aa commented
q = padarray(q1,[numRowsPad numColsPad numSlcsPad],NaN,'both');

% Quantize the image
%nL = 16;
% if any(isnan(q)) % aa commented
%     nL = nL-1; % aa commented
% end % aa commented
%q = imquantize_cerr(scanArrayTmp3M,nL); % aa commented
%clear scanArrayTmp3M; % aa commented
qmax = max(q(:));
nanFlag = 0;
if any(isnan(q(:)))
    nanFlag = 1;
    q(isnan(q))=qmax+1;
end
qs=sort(unique(q));
lq=length(qs);

for k = 1:length(qs)
    q(q==qs(k)) = k;
end

q = uint16(q); % q is the quantized image
%numSlcsWithPadding = size(q,3);

% % Create indices for 2D blocks
% [m,n,~] = size(q);
% m = uint32(m);
% n = uint32(n);
% colWindow = uint32(colWindow);
% rowWindow = uint32(rowWindow);
% slcWindow = uint32(slcWindow);
%
% % Index calculation adapted from
% % http://stackoverflow.com/questions/25449279/efficient-implementation-of-im2col-and-col2im
%
% %// Start indices for each block
% start_ind = reshape(bsxfun(@plus,[1:m-rowWindow+1]',[0:n-colWindow]*m),[],1); %//'
%
% %// Row indices
% lin_row = permute(bsxfun(@plus,start_ind,[0:rowWindow-1])',[1 3 2]);  %//'
%
% %// Get linear indices based on row and col indices and get desired output
% % imTmpM = A(reshape(bsxfun(@plus,lin_row,[0:ncols-1]*m),nrows*ncols,[]));
% indM = reshape(bsxfun(@plus,lin_row,(0:colWindow-1)*m),rowWindow*colWindow,[]);

% Create indices for 2D blocks. In this case all voxels
indM = 1:numel(q);

numOffsets = size(offsetsM,1);

% Indices of last level to filter out
nanIndV = false([lq*lq,1]);
nanIndV([lq:lq:lq*lq-lq, lq*lq-lq:lq*lq]) = true;

% Build levels vector for mu, sig
levRowV = repmat(1:lq,[1 lq]);
levColV = repmat(1:lq,[lq 1]);
levColV = levColV(:)';

% Build list of indices for contrast calculation
for n=0:lq-1
    % indices for p(x-y), contrast
    indCtrstV = false(lq*lq,1);
    indCtrst1V = 1:lq-n;
    indCtrst2V = 1+n:lq;
    indCtrstTmpV = indCtrst1V + (indCtrst2V-1)*lq;
    indCtrstTmpV = [indCtrstTmpV indCtrst2V + (indCtrst1V-1)*lq];
    indCtrstV(indCtrstTmpV) = 1;
    indCtrstV(nanIndV) = [];
    indCtrstC{n+1} = indCtrstV;
    
    % indices for p(x+y)
    indPxPlusYv = false(lq*lq,1);
    indPxPlusYv(levRowV + levColV == n+2) = 1;
    indPxPlusYv(nanIndV) = [];
    indPxPlusYc{n+1} = indPxPlusYv;
    
    % indices for px
    indPxV = false(lq*lq,1);
    indPxV(lq*n+1:lq*(n+1)) = true;
    indPxV(nanIndV) = [];
    indPxC{n+1} = indPxV;
end

% Filter NaN indices from row/col levels
levRowV(nanIndV) = [];
levColV(nanIndV) = [];

% Build linear indices column/row-wise for Symmetry
indRowV = zeros(1,lq*lq);
for i=1:lq
    indRowV((i-1)*lq+1:(i-1)*lq+lq) = i:lq:lq*lq;
end

% Initialize
energyV = [];
entropyV = [];
sumAvgV = [];
corrcorrV = [];
invDiffMomV = [];
contrastV = [];
clustShadeV = [];
clustProminV = [];

tic
for off = 1:numOffsets
    % Initialize cooccurrence matrix (vectorized for speed)
    cooccurV = zeros(lq*lq,1,'single');
    
    offset = offsetsM(off,:);
    slc1M = q(numRowsPad+(1:numRows),numColsPad+(1:numCols),...
        numSlcsPad+(1:numSlices));
    slc2M = circshift(q,offset);
    slc2M = slc2M(numRowsPad+(1:numRows),numColsPad+(1:numCols),numSlcsPad+(1:numSlices))...
        + (slc1M-1)*lq;
    cooccurV = cooccurV + accumarray(slc2M(:),1, [lq*lq,1]); % patch-wise cooccurance
    cooccurV = cooccurV + cooccurV(indRowV,:); % for symmetry
    cooccurV(nanIndV,:) = [];
    cooccurV = cooccurV./sum(cooccurV);
    % Calculate scalar texture for this offset
    % Angular Second Moment (Energy)
    if flagv(1)
        energyV(off) = sum(cooccurV.^2);
    end
    % Entropy
    if flagv(2)
        entropyV(off) = -sum(cooccurV.*log2(cooccurV+1e-10));
    end
    % Contrast, inverse Difference Moment
    contrastV(off) = 0;
    invDiffMomV(off) = 0;
    for n=0:lq-1
        % px
        px(n+1) = sum(cooccurV(indPxC{n+1},:),1);
        % p(x+y)
        pXplusY = cooccurV(indCtrstC{n+1},:);
        % p(x-y)
        pXminusY = cooccurV(indCtrstC{n+1},:);
        % contrast
        if flagv(6)
            contrastV = contrastV + ...
                sum(n^2*cooccurV(indCtrstC{n+1},:));
        end
        % inv diff moment
        if flagv(5)
            invDiffMomV = invDiffMomV + ...
                sum((1/(1+n^2))*cooccurV(indCtrstC{n+1},:));
        end
    end
    % weighted pixel average (mu), weighted pixel variance (sig)
    mu = (1:nL) * px';
    sig = ((1:nL)-mu).^2 * px';
    %px = sum(cooccurV(indCooccurM),2);
    muX = mean(px);
    sigX = std(px);
    %         for colNum = 1:numCalcVoxs
    clstrV = (levRowV + levColV - 2*mu);
    % Cluster Shade
    if flagv(7)
        clustShadeV(off) = clstrV.*clstrV.*clstrV * cooccurV(:,1);
    end
    % Cluster Prominence
    %             clustProminTmpV(colNum) = (levRowV + levColV - 2*mu(colNum)).^4 ...
    %                 * cooccurPatchM(:,colNum);
    if flagv(8)
        clustProminV(off) = clstrV.*clstrV.*clstrV.*clstrV ...
            * cooccurV(:,1);
    end
    % Sum Avg
    if flagv(3)
        sumAvgV(off) = (levRowV + levColV + 2) * cooccurV(:,1);
    end
    % Correlation
    if flagv(4)
        corrV(off) = (levRowV .* levColV *cooccurV(:,1) - ...
            mu(1)*mu(1)) / var(1); % check this
    end
    
    %         end
end

%     % Average texture from all directions
%     energyV = energyV / numOffsets;
%     entropyV = entropyV / numOffsets;
%     contrastV = contrastV / numOffsets;
%     invDiffMomV = invDiffMomV / numOffsets;
%     clustShadeV = clustShadeV / numOffsets;
%     clustProminV = clustProminV / numOffsets;

%     if flagv(1)
%         energyV = energyV / numOffsets;
%     end
%     if flagv(2)
%         entropyV = entropyV / numOffsets;
%     end
%     if flagv(3)
%         sumAvgV = sumAvgV / numOffsets;
%     end
%     if flagv(4)
%         corrV = corrV / numOffsets;
%     end
%
%     if flagv(6)
%         contrastV = contrastV / numOffsets;
%     end
%     if flagv(5)
%         invDiffMomV = invDiffMomV / numOffsets;
%     end
%     if flagv(7)
%         clustShadeV = clustShadeV / numOffsets;
%     end
%     if flagv(8)
%         clustProminV = clustProminV / numOffsets;
%     end

%     if waitbarFlag
%         set(hWait, 'Vertices', [[0 0 slcNum/numSlices slcNum/numSlices]' [0 1 1 0]']);
%         drawnow;
%     end

% end
toc

