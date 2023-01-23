function domOrient3M = calcDominantOrientation(scanArray3M, mask3M, patchSizeV, dim2d3dFlag, hWait)
% function domOrient3M = calcDominantOrientation(scanArray3M, mask3M, patchSizeV, dim2d3dFlag, hWait)
%
% Dominant orientation calculation.
%
% APA, 10/14/2016

% Flag to draw waitbar
waitbarFlag = 0;
if exist('hWait','var') & ishandle(hWait)
    waitbarFlag = 1;
end

% Get indices of non-NaN voxels
calcIndM = ~isnan(scanArray3M) & mask3M;

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
numVoxels = numRows*numCols;

% Pad q, so that sliding window works also for the edge voxels
if exist('padarray.m','file')
    %scanArrayTmp3M = padarray(scanArray3M,[numRowsPad numColsPad
    %numSlcsPad],NaN,'both'); % aa commented
    q = padarray(scanArray3M,[numRowsPad numColsPad numSlcsPad],NaN,'both');
else
    q = padarray_oct(scanArray3M,[numRowsPad numColsPad numSlcsPad],NaN,'both');
end

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

[Fx,Fy] = gradient(q);
%Fx = abs(Fx);
%Fy = abs(Fy);

domOrient3M = zeros(size(scanArray3M));
domOrient2M = zeros(size(scanArray3M(:,:,1)));

tic
% Iterate over slices. compute cooccurance for all patches per slice
for slcNum = 1:numSlices %(1+numSlcsPad):(numSlices+numSlcsPad)
    
    disp(['--- Orientation Calculation for Slice # ', num2str(slcNum), ' ----']) 
    
    calcSlcIndV = calcIndM(:,:,slcNum);
    calcSlcIndV = calcSlcIndV(:);
    numCalcVoxs = sum(calcSlcIndV);
    
    indSlcM = indM(:,calcSlcIndV);
    
    FxSlc = Fx(:,:,slcNum+numSlcsPad);
    FySlc = Fy(:,:,slcNum+numSlcsPad);

    domOrientM = zeros(2,numCalcVoxs);
    for i = 1:numCalcVoxs % size(indSlcM,2)
        Y = [FxSlc(indSlcM(:,i)) FySlc(indSlcM(:,i))];
        Y(sum(isnan(Y),2)>0,:) = [];
        %pp = pca(Y);
        %pp1M(:,i) = pp(1,:)';
        if ~isempty(Y)
            [Usvd, S, Vsvd] = svd(Y);
            domOrientM(:,i) = Vsvd(:,1);
        end
    end
    domOrientSlc2M = domOrient2M;
    domOrientSlc2M(calcSlcIndV) = atan2(domOrientM(2,:),domOrientM(1,:));
    domOrient3M(:,:,slcNum) = domOrientSlc2M;
    
    if waitbarFlag
        set(hWait, 'Vertices', [[0 0 slcNum/numSlices slcNum/numSlices]' [0 1 1 0]']);
        drawnow;
    end 
    
end
toc

