function [energy3M,entropy3M,invDiffMom3M,contrast3M,clustShade3M,clustPromin3M] = textureByPatch(scanArray3M, deltaXYZv, patchSizeV, offsetV)
% function [energy3M,entropy3M,invDiffMom3M,contrast3M,clustShade3M,clustPromin3M] = textureByPatch(scanArray3M, deltaXYZv, patchSizeV, offsetV)
%
% Patch-wise texture calculation.
%
% APA, 09/09/2015

% Get indices of non-NaN voxels
calcIndM = ~isnan(scanArray3M);

% Grid resolution
deltaX = deltaXYZv(1);
deltaY = deltaXYZv(2);
deltaZ = deltaXYZv(3);

% Get Block size to process
slcWindow = floor(2*patchSizeV(3)/deltaZ);
rowWindow = floor(2*patchSizeV(1)/deltaY);
colWindow = floor(2*patchSizeV(2)/deltaX);

% Make sure that the window is of odd size
if mod(slcWindow,2) == 0
    slcWindow = slcWindow + 1;
end
if mod(rowWindow,2) == 0
    rowWindow = rowWindow + 1;
end
if mod(colWindow,2) == 0
    colWindow = colWindow + 1;
end

% Build distance matrices
numColsPad = floor(colWindow/2);
numRowsPad = floor(rowWindow/2);
numSlcsPad = floor(slcWindow/2);

% Get number of voxels per slice
[numRows, numCols, numSlices] = size(scanArray3M);
numVoxels = numRows*numCols;

% Pad doseArray2 so that sliding window works also for the edge voxels
scanArrayTmp3M = padarray(scanArray3M,[numRowsPad numColsPad numSlcsPad],NaN,'both');

% Quantize the image
nL = 16;
if any(isnan(scanArrayTmp3M))
    nL = nL-1;
end
q = imquantize_cerr(scanArrayTmp3M,nL);
clear scanArrayTmp3M;
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

q = uint8(q); % q is the quantized image
numSlcsWithPadding = size(q,3);

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
offsetsM = [ 1  0  0;
             0  1  0;
             1  1  0;
             1 -1  0;
             1  0  1;
             0  1  1;
             1  1  1;
             1 -1  1;
             0  0  1;
            -1  0  1;
            -1 -1  1;
             0 -1  1;
             1 -1  1];
numOffsets = size(offsetsM,1);

% Indices of last level to filter out
nanIndV = false([lq*lq,1]);
nanIndV([lq:lq:lq*lq-lq, lq*lq-lq:lq*lq]) = true;

% Build list of indices for contrast calculation
for n=0:lq-1
    indCtrstV = false(lq*lq,1);
    indCtrst1V = 1:lq-n;
    indCtrst2V = 1+n:lq;
    indCtrstTmpV = indCtrst1V + (indCtrst2V-1)*lq;
    indCtrstTmpV = [indCtrstTmpV indCtrst2V + (indCtrst1V-1)*lq];
    indCtrstV(indCtrstTmpV) = 1;
    indCtrstV(nanIndV) = [];
    indCtrstC{n+1} = indCtrstV;
end

% Build linear indices column/row-wise for Symmetry
indRowV = zeros(1,lq*lq);
for i=1:lq
    indRowV((i-1)*lq+1:(i-1)*lq+lq) = i:lq:lq*lq;
end

% Build levels vector for mu, sig
levRowV = repmat(1:lq,[1 lq]);
levColV = repmat(1:lq,[lq 1]);
levColV = levColV(:)';
levRowV(nanIndV) = [];
levColV(nanIndV) = [];

% Initialize
energy3M = zeros([numRows, numCols, numSlices],'single');
entropy3M = zeros([numRows, numCols, numSlices],'single');
contrast3M = zeros([numRows, numCols, numSlices],'single');
invDiffMom3M = zeros([numRows, numCols, numSlices],'single');
clustShade3M = zeros([numRows, numCols, numSlices],'single');
clustPromin3M = zeros([numRows, numCols, numSlices],'single');

tic
% Iterate over slices. compute cooccurance for all patches per slice
parfor slcNum = 1:numSlices
    disp(['--- Texture Calculation for Slice # ', num2str(slcNum), ' ----']) 
    energyV = zeros(1,numVoxels,'single');
    entropyV = zeros(1,numVoxels,'single');
    contrastV = zeros(1,numVoxels,'single');
    invDiffMomV = zeros(1,numVoxels,'single');
    clustShadeV = zeros(1,numVoxels,'single');
    clustProminV = zeros(1,numVoxels,'single');
    calcSlcIndV = calcIndM(:,:,slcNum);
    calcSlcIndV = calcSlcIndV(:);
    numCalcVoxs = sum(calcSlcIndV);
    indSlcM = indM(:,calcSlcIndV);
    % List of Voxel numbers
    voxelNumsV = uint32(0:lq*lq:lq*lq*(numCalcVoxs-1));    
    for off = 1:numOffsets
        cooccurPatchM = zeros(lq*lq*numCalcVoxs,1,'single');
        %cooccurPatchTmpV = zeros(lq*lq*numCalcVoxs,1,'single');
        offset = offsetsM(off,:);        
        for slc = slcNum:slcNum+slcWindow-1 % slices within the patch
            if slc+offset(3) > numSlcsWithPadding
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
            slc2M = bsxfun(@plus,uint32(slc2M(indSlcM)),voxelNumsV);
            cooccurPatchM = cooccurPatchM + accumarray(slc2M(:),1, [lq*lq*numCalcVoxs,1]); % patch-wise cooccurance
        end
        cooccurPatchM = reshape(cooccurPatchM,lq*lq,numCalcVoxs);
        cooccurPatchM = cooccurPatchM + cooccurPatchM(indRowV,:); % for symmetry
        cooccurPatchM(nanIndV,:) = [];
        cooccurPatchM = bsxfun(@rdivide,cooccurPatchM,sum(cooccurPatchM)+1e-5);
        % Calculate scalar texture for this offset
        % Angular Second Moment (Energy)
        energyV(calcSlcIndV) = energyV(calcSlcIndV) + sum(cooccurPatchM.^2);
        % Entropy
        entropyV(calcSlcIndV) = entropyV(calcSlcIndV) - ...
            sum(cooccurPatchM.*log2(cooccurPatchM+1e-10));
        % Contrast, inverse Difference Moment
        for n=0:lq-1
            contrastV(calcSlcIndV) = contrastV(calcSlcIndV) + ...
                sum(n^2*cooccurPatchM(indCtrstC{n+1},:));
            invDiffMomV(calcSlcIndV) = invDiffMomV(calcSlcIndV) + ...
                sum((1/1+n)^2*cooccurPatchM(indCtrstC{n+1},:));
        end 
        % weighted pixel average (mu), weighted pixel variance (sig)
        mu = levRowV*cooccurPatchM;
        sig = zeros(1,numCalcVoxs);
        clustShadeTmpV  = zeros(1,numCalcVoxs);
        clustProminTmpV = zeros(1,numCalcVoxs);
        for colNum = 1:numCalcVoxs
            sig(colNum) = (levRowV-mu(colNum)).^2*cooccurPatchM(:,colNum);
            clstrV = (levRowV + levColV - 2*mu(colNum));
            % Cluster Shade
            clustShadeTmpV(colNum) = clstrV.*clstrV.*clstrV * cooccurPatchM(:,colNum);
            % Cluster Prominence
%             clustProminTmpV(colNum) = (levRowV + levColV - 2*mu(colNum)).^4 ...
%                 * cooccurPatchM(:,colNum);
            clustProminTmpV(colNum) = clstrV.*clstrV.*clstrV.*clstrV ...
                * cooccurPatchM(:,colNum);
        end
        clustShadeV(calcSlcIndV) = clustShadeV(calcSlcIndV) + clustShadeTmpV;
        clustProminV(calcSlcIndV) = clustProminV(calcSlcIndV) + clustProminTmpV;
    end
    % Average texture from all directions
    energyV = energyV / numOffsets;
    entropyV = entropyV / numOffsets;
    contrastV = contrastV / numOffsets;
    invDiffMomV = invDiffMomV / numOffsets;
    clustShadeV = clustShadeV / numOffsets;
    clustProminV = clustProminV / numOffsets;
    energy3M(:,:,slcNum) = reshape(energyV(:),[numRows, numCols]);
    entropy3M(:,:,slcNum) = reshape(entropyV(:),[numRows, numCols]);
    contrast3M(:,:,slcNum) = reshape(contrastV(:),[numRows, numCols]);
    invDiffMom3M(:,:,slcNum) = reshape(invDiffMomV(:),[numRows, numCols]);
    clustShade3M(:,:,slcNum) = reshape(clustShadeV(:),[numRows, numCols]);
    clustPromin3M(:,:,slcNum) = reshape(clustProminV(:),[numRows, numCols]);
end
toc

