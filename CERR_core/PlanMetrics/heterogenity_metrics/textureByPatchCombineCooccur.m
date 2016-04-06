function [energy3M,entropy3M,sumAvg3M,corr3M,invDiffMom3M,contrast3M,...
    clustShade3M, clustPromin3M] = textureByPatchCombineCooccur(...
    scanArray3M, patchSizeV, offsetsM, flagv, hWait)
% function [energy3M,entropy3M,sumAvg3M,corr3M,invDiffMom3M,contrast3M,...
%     clustShade3M, clustPromin3M] = textureByPatchCombineCooccur(...
%     scanArray3M, patchSizeV, offsetsM, flagv, hWait)
%
% Patch-wise texture calculation.
%
% APA, 09/09/2015

% Generate flags
if ~exist('flagv','var')
    flagv = ones(1,8);
elseif exist('flagv','var') && isempty(flagv)
    flagv = ones(1,8);
end

% Flag to draw waitbar
waitbarFlag = 0;
if exist('hWait','var') && ishandle(hWait)
    waitbarFlag = 1;
end

% Get indices of non-NaN voxels
calcIndM = ~isnan(scanArray3M);

% % Grid resolution
% deltaX = deltaXYZv(1);
% deltaY = deltaXYZv(2);
% deltaZ = deltaXYZv(3);

% % Get Block size to process
% slcWindow = 2 * floor(patchSizeV(3)/deltaZ) + 1;
% rowWindow = 2 * floor(patchSizeV(1)/deltaY) + 1;
% colWindow = 2 * floor(patchSizeV(2)/deltaX) + 1;

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

% Pad doseArray2 so that sliding window works also for the edge voxels
scanArrayTmp3M = padarray(scanArray3M,[numRowsPad numColsPad numSlcsPad],NaN,'both');

% Quantize the image
nL = 16;
nanFlag = 0;
nanFlag = 1;
if any(isnan(scanArrayTmp3M))
    nL = nL-1;
end
q = imquantize_cerr(scanArrayTmp3M,nL);
clear scanArrayTmp3M;
qmax = max(q(:));
if nanFlag    
    q(isnan(q)) = qmax+1;
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

% Start indices for each block
start_ind = reshape(bsxfun(@plus,[1:m-rowWindow+1]',[0:n-colWindow]*m),[],1);

% Row indices
lin_row = permute(bsxfun(@plus,start_ind,[0:rowWindow-1])',[1 3 2]);

% Get linear indices based on row and col indices and get desired output
indM = reshape(bsxfun(@plus,lin_row,(0:colWindow-1)*m),rowWindow*colWindow,[]);

% % Directional offsets
% offsetsM = [ 1  0  0;
%              0  1  0;
%              1  1  0;
%              1 -1  0;
%              1  0  1;
%              0  1  1;
%              1  1  1;
%              1 -1  1;
%              0  0  1;
%             -1  0  1;
%             -1 -1  1;
%              0 -1  1;
%              1 -1  1];

numOffsets = size(offsetsM,1);

% Indices of last level to filter out if there are NaNs in the image
nanIndV = false([lq*lq,1]);
if nanFlag
    nanIndV([lq:lq:lq*lq-lq, lq*lq-lq:lq*lq]) = true;
end

% Build list of indices for contrast, homogenity calculation
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
levRowV = repmat(1:lq,[1 lq])-1;
levColV = repmat(1:lq,[lq 1])-1;
levColV = levColV(:)';
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
    calcSlcIndV = calcIndM(:,:,slcNum);
    calcSlcIndV = calcSlcIndV(:);
    numCalcVoxs = sum(calcSlcIndV);
    indSlcM = indM(:,calcSlcIndV);
    % List of Voxel numbers
    voxelNumsV = uint32(0:lq*lq:lq*lq*(numCalcVoxs-1));    
    totalIndices = lq*lq*numCalcVoxs;
    %expectedFill = double(round(0.2*totalIndices));
    %cooccurPatchM = sparse([],[],[],totalIndices,1,expectedFill);
    cooccurPatchM = sparse([],[],[],totalIndices,1);
    for off = 1:numOffsets
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
            slc2M = bsxfun(@plus,uint32(slc2M(indSlcM)),voxelNumsV);
            cooccurPatchM = cooccurPatchM + accumarray(slc2M(:),1, [lq*lq*numCalcVoxs,1]); % patch-wise cooccurance
        end
    end
    % Average texture from all directions
    cooccurPatchM = reshape(cooccurPatchM,lq*lq,numCalcVoxs);
    cooccurPatchM = cooccurPatchM + cooccurPatchM(indRowV,:); % for symmetry
    cooccurPatchM(nanIndV,:) = [];
    cooccurPatchM = bsxfun(@rdivide,cooccurPatchM,sum(cooccurPatchM)+1e-5);
    % Calculate scalar texture for this offset
    % Angular Second Moment (Energy)
    if flagv(1)
        energyV(calcSlcIndV) = energyV(calcSlcIndV) + sum(cooccurPatchM.^2);
    end
    % Entropy
    if flagv(2)
        entropyV(calcSlcIndV) = entropyV(calcSlcIndV) - ...
            sum(cooccurPatchM.*log2(cooccurPatchM+1e-10));
    end
    % Contrast, inverse Difference Moment    
    for n=0:lq-1
        if flagv(5)
            invDiffMomV(calcSlcIndV) = invDiffMomV(calcSlcIndV) + ...
                sum((1/(1+n*n))*cooccurPatchM(indCtrstC{n+1},:));
        end
        if flagv(6)
            contrastV(calcSlcIndV) = contrastV(calcSlcIndV) + ...
                sum(n^2*cooccurPatchM(indCtrstC{n+1},:));
        end
    end        
    % weighted pixel average (mu), weighted pixel variance (sig)
    mu = (levRowV)*cooccurPatchM;
    var = zeros(1,numCalcVoxs);
    clustShadeTmpV  = zeros(1,numCalcVoxs);
    clustProminTmpV = zeros(1,numCalcVoxs);
    sumAvgTmpV      = zeros(1,numCalcVoxs);
    corrTmpV        = zeros(1,numCalcVoxs);
    for colNum = 1:numCalcVoxs
        var(colNum) = (levRowV-mu(colNum)).^2*cooccurPatchM(:,colNum) + 0.0001;
        clstrV = (levRowV + levColV - 2*mu(colNum));
        % Cluster Shade
        if flagv(7)
            clustShadeTmpV(colNum) = clstrV.*clstrV.*clstrV * cooccurPatchM(:,colNum);
        end
        % Cluster Prominence
        if flagv(8)
            clustProminTmpV(colNum) = clstrV.*clstrV.*clstrV.*clstrV ...
                * cooccurPatchM(:,colNum);
        end
        % Sum Avg
        if flagv(3)
            sumAvgTmpV(colNum) = (levRowV + levColV + 2) * cooccurPatchM(:,colNum);
        end
        % Correlation
        if flagv(4)
            corrTmpV(colNum) = (levRowV .* levColV *cooccurPatchM(:,colNum) - ...
                mu(colNum)*mu(colNum)) / var(colNum);
        end
    end
    if flagv(7)
        clustShadeV(calcSlcIndV) = clustShadeV(calcSlcIndV) + clustShadeTmpV;
    end
    if flagv(8)
        clustProminV(calcSlcIndV) = clustProminV(calcSlcIndV) + clustProminTmpV;
    end
    if flagv(3)
        sumAvgV(calcSlcIndV) = sumAvgV(calcSlcIndV) + sumAvgTmpV;
    end
    if flagv(4)
        corrV(calcSlcIndV) = corrV(calcSlcIndV) + corrTmpV;
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
    
    if waitbarFlag
        set(hWait, 'Vertices', [[0 0 slcNum/numSlices slcNum/numSlices]' [0 1 1 0]']);
        drawnow;
    end       
end
toc

