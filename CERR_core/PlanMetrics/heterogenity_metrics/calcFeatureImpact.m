function feature3M = calcFeatureImpact(scanNum, structNum, ...
    patchSizeV, featureFun, featureName, planC, varargin)
% function feature3M = calcFeatureImpact(scanNum, structNum, patchSizeV, hWait, varargin)
%
% This function computes the feature Impact at each voxel.
% 
% Method:
% 1> Omit the voxel and its neighborhood.
% 2> Compute the feature with the passed featureFun and the varargin.
% Repeat 1 and 2 for each voxel in the region of interest
%
% Example:
%
% In order to compute the impact map for 1st order kurtosis,
% scanNum = 1;
% structNum = 6;
% patchRadiusV = [2 2 0];
% funcHandle = @radiomics_first_order_stats;
% featureName = 'kurtosis';
% feature3M = calcFeatureImpact(planC, structNum, patchRadiusV,...
%   funcHandle, featureName, planC);
%
% Also, refer to call_calcFeatureImpact.m for an example to calculate
% feature impact for RLM features
%
% APA, 5/18/2017

% Flag to draw waitbar
waitbarFlag = 0;
% if exist('hWait','var') && ishandle(hWait)
%     waitbarFlag = 1;
% end

if iscell(planC)
    indexS = planC{end};
    
    % Get uniformized structure Mask
    struct3M = getUniformStr(structNum,planC);
    
    % Get uniformized scan mask in HU
    %scanNum = getAssociatedScan(planC{indexS.structures}(structNum).assocScanUID, planC);
    scan3M = getUniformizedCTScan(1, scanNum, planC);
    % Convert to HU if image is of type CT
    if ~isempty(planC{indexS.scan}(scanNum).scanInfo(1).CTOffset)
        scan3M = double(scan3M) - planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;
    end
    
    fullScanSiz = size(scan3M);
    
    % Crop scan within the structures bounding box
    [minr, maxr, minc, maxc, mins, maxs] = compute_boundingbox(struct3M);
    struct3M = struct3M(minr:maxr,minc:maxc,mins:maxs);
    scan3M = scan3M(minr:maxr,minc:maxc,mins:maxs);
    scan3M(struct3M==0)     = NaN;
    
    
else
    
    scan3M = planC;
    struct3M = structNum;
end

% Initialize the feature3M matrix
feature3M = zeros(fullScanSiz);

featureCropped3M = zeros(size(scan3M));

% Get indices of non-NaN voxels
calcIndM = struct3M == 1;

% % Grid resolution
slcWindow = 2 * patchSizeV(3) + 1;
rowWindow = 2 * patchSizeV(1) + 1;
colWindow = 2 * patchSizeV(2) + 1;

% Build distance matrices
numColsPad = floor(colWindow/2);
numRowsPad = floor(rowWindow/2);
numSlcsPad = floor(slcWindow/2);

% Get number of voxels per slice
[numRows, numCols, numSlices] = size(scan3M);
numVoxels = numRows*numCols;

% Pad q, so that sliding window works also for the edge voxels
%scanArrayTmp3M = padarray(scanArray3M,[numRowsPad numColsPad
%numSlcsPad],NaN,'both'); % aa commented
q = padarray(scan3M,[numRowsPad numColsPad numSlcsPad],NaN,'both');
structPadded3M = padarray(uint32(struct3M),[numRowsPad numColsPad numSlcsPad],NaN,'both');
structPadded3M = logical(structPadded3M);
calcIndM = padarray(calcIndM,[0 0 numSlcsPad],0,'both');

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

tic

% Feature with all the voxels
scanTmp3M = q;
scanTmp3M(~structPadded3M) = [];
% featureEntireStruct = feval(featureFun,scanTmp3M(:),structPadded3M(:),varargin{:});
quantizeFlag = 1;
featureEntireStruct = feval(featureFun,scanTmp3M,structPadded3M,...
    quantizeFlag, varargin{:});
if ~isempty(featureName) && isstruct(featureEntireStruct)
    [f1,f2] = strtok(featureName,'.');
    fieldC = {f1};
    while ~isempty(f2)
        [f1,f2] = strtok(f2,'.');
        fieldC{end+1} = f1;
    end
    for i = 1:length(fieldC)
        featureEntireStruct = featureEntireStruct.(fieldC{i});
    end
end

% Iterate over slices. compute cooccurance for all patches per slice
parfor slcNum = (1+numSlcsPad):(numSlices+numSlcsPad)
    
    disp(['--- Feature Impact Calculation for Slice # ', num2str(slcNum), ' ----']) 
    
    calcSlcIndV = calcIndM(:,:,slcNum);    
    calcSlcIndV = calcSlcIndV(:);
    numCalcVoxs = sum(calcSlcIndV);
    indSlcM = indM(:,calcSlcIndV);
    slcV = slcNum-patchSizeV(3):slcNum+patchSizeV(3);
    featureV = zeros(numCalcVoxs,1);
    for vox = 1:size(indSlcM,2)
       structTmp3M = structPadded3M;
       % scanTmp3M = q;
       for slcNumTmp = 1:length(slcV)
           slc = slcV(slcNumTmp);
           structSlcM = structTmp3M(:,:,slc);
           structSlcM(indSlcM(:,vox)) = 0;
           structTmp3M(:,:,slc) = structSlcM;
       end
       %scanTmp3M(~structTmp3M) = [];
       % featureVox = feval(featureFun,scanTmp3M(:),structTmp3M(:),varargin{:});
       featureVox = feval(featureFun,scanTmp3M,structTmp3M,...
           quantizeFlag,varargin{:});
       for i = 1:length(fieldC)
           featureVox = featureVox.(fieldC{i});
       end       
       featureV(vox) = featureVox;
       % featureV(vox) = featureS.kurtosis;
       disp('done')
    end
    indScanTmp3M = zeros(size(calcIndM),'logical');
    indScanTmp3M(:,:,slcNum) = calcIndM(:,:,slcNum);
    featuresC{slcNum} = featureV;
    calcIndC{slcNum} = indScanTmp3M;
    % featureCropped3M(indScanTmp3M) = featureV;
    
    %if waitbarFlag
    %    set(hWait, 'Vertices', [[0 0 slcNum/numSlices slcNum/numSlices]' [0 1 1 0]']);
    %    drawnow;
    %end 
    
end

for slcNum = (1+numSlcsPad):(numSlices+numSlcsPad)
    featureCropped3M(calcIndC{slcNum}) = featuresC{slcNum};
end

featureCropped3M(calcIndM) = ...
    (featureCropped3M(calcIndM) - featureEntireStruct) / featureEntireStruct * 100;
feature3M(minr:maxr,minc:maxc,mins:maxs) = featureCropped3M;

toc

% Write feature impact as a dose in CERR

% Create Texture Scans
[xVals, yVals, zVals] = getUniformScanXYZVals(planC{indexS.scan}(scanNum));
deltaXYZv(1) = abs(xVals(2)-xVals(1));
deltaXYZv(2) = abs(yVals(2)-yVals(1));
deltaXYZv(3) = abs(zVals(2)-zVals(1));
uniqueSlicesV = mins:maxs;
zV = zVals(uniqueSlicesV);
regParamsS.horizontalGridInterval = deltaXYZv(1);
regParamsS.verticalGridInterval   = -deltaXYZv(2); %(-)ve for dose
regParamsS.coord1OFFirstPoint   = xVals(minc);
regParamsS.coord2OFFirstPoint   = yVals(minr); % for dose
%regParamsS.coord2OFFirstPoint   = yVals(maxr);
regParamsS.zValues  = zV;
regParamsS.sliceThickness = [planC{indexS.scan}(scanNum).scanInfo(uniqueSlicesV).sliceThickness];
assocScanUID = planC{indexS.structures}(structNum).assocScanUID;
dose2CERR(featureCropped3M,[], 'Kurtosis','test','test','non CT',regParamsS,'no',assocScanUID)


