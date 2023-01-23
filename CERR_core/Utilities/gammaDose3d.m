function gammaM = gammaDose3d(doseArray1, doseArray2, strMask3M, deltaXYZv,...
    doseAgreement, distAgreement, maxSearchDistance, thresholdAbsolute, doseDiffMethod)
% function gammaM = gammaDose3d(doseArray1, doseArray2, strMask3M, deltaXYZv,...
% doseAgreement, distAgreement, maxSearchDistance, thresholdAbsolute, doseDiffMethod)
%
% This function returns the Gamma calculation for input dose distributions.
% 
% Computation uses the following algorithm for speedup:
% "A fast algorithm for gamma evaluation in 3D”,
%  Wendling et al, Medical physics,  34 (5), pp. 1647, 2007.
%
% which achieves speed and computer memory efficiency by searching around 
% each reference point with increasing distance in a sphere, 
% which has a radius of a chosen maximum search distance.
%
% doseArray1: reference dose
%
% doseArray2: evaluation dose
%
% strMask3M: binary mask. Gamma value is computed only for voxels that 
%            have a strMask3M value of 1 
%
% deltaXYZv: Voxel size (dx,dy,dz) in cm
%
% doseDiffMethod: method to account for dose difference. 
% 1: single dose value, usually percentage of max reference dose.
% 2: percentage of dose at each voxel.
%
% doseAgreement: when doseDiffMethod = 1, this is specified in Gy.
%                when doseDiffMethod = 2, this is specified as a percentage.
%
% distAgreement: distance agreement in cm.
%
% maxSearchDistance: maximum radius of sphere as described in Wendling et al.
%
% thresholdAbsolute: Dose in Gy. for which gamma calculation is ignored.
%
% APA, 08/28/2015

deltaX = deltaXYZv(1);
deltaY = deltaXYZv(2);
deltaZ = deltaXYZv(3);

% Get Block size to process
if ~exist('maxSearchDistance', 'var') || ...
        (exist('maxSearchDistance', 'var') && isempty(maxSearchDistance))
    maxSearchDistance = distAgreement*2;
end
%maxSearchDistance = 1; % cm
slcWindow = floor(2*maxSearchDistance/deltaZ);
rowWindow = floor(2*maxSearchDistance/deltaY);
colWindow = floor(2*maxSearchDistance/deltaX);

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
numCols = floor(colWindow/2);
numRows = floor(rowWindow/2);
numSlcs = floor(slcWindow/2);
xV = -numCols*deltaX:deltaX:numCols*deltaX;
yV = -numRows*deltaY:deltaY:numRows*deltaY;
zV = -numSlcs*deltaZ:deltaZ:numSlcs*deltaZ;
[yM,xM] = ndgrid(yV,xV);
xysq = xM(:).^2 + yM(:).^2;

% Pad doseArray2 so that sliding window works also for the edge voxels
if exist('padarray.m','file')
    doseArray2 = padarray(doseArray2,...
        [floor(rowWindow/2), floor(colWindow/2), floor(slcWindow/2)],NaN,'both');
else
    doseArray2 = padarray_oct(doseArray2,...
        [floor(rowWindow/2), floor(colWindow/2), floor(slcWindow/2)],NaN,'both');
end

% Create indices for 2D blocks
[m,n,~] = size(doseArray2);
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


% Find regions not included in structure or having dose below threshold
%gammaM(doseArray1 <= thresholdAbsolute) = 0;
calcIndM = strMask3M & doseArray1 > thresholdAbsolute;

% Initialize gammaM
gammaM = Inf*zeros(size(doseArray1),'single');
gammaM(~calcIndM) = NaN;

% Update waitbar on gamma GUI
gammaGUIFig = findobj('tag','CERRgammaInputGUI');
if ~isempty(gammaGUIFig)
    ud = get(gammaGUIFig,'userdata');
    set(ud.wb.patch,'xData',[0 0 0 0])
end

tic
siz = size(doseArray1(:,:,1));
numSlices = size(doseArray1,3);
for slcNum = 1:numSlices
    disp(['--- Gamma Calculation for Slice # ', num2str(slcNum), ' ----'])
    calcSlcIndV = calcIndM(:,:,slcNum);
    calcSlcIndV = calcSlcIndV(:);
    
    if sum(calcSlcIndV) == 0
        continue
    end
    
    % Get voxels for this slice
    indSlcM = indM(:,calcSlcIndV);

    gammaV = gammaM(:,:,slcNum);
    gammaV = gammaV(:)';
    slc1M = doseArray1(:,:,slcNum);
    slcCount = 1;
    for slc = slcNum:slcWindow+slcNum-1
        slc2M = doseArray2(:,:,slc);
        tmpGammaV = bsxfun(@minus,slc2M(indSlcM),slc1M(calcSlcIndV)');
        if doseDiffMethod == 1
            tmpGammaV = bsxfun(@plus,tmpGammaV.^2/doseAgreement^2 , (xysq + zV(slcCount)^2) / distAgreement^2);
        elseif doseDiffMethod == 2
            tmpGammaV = bsxfun(@rdivide,tmpGammaV.^2,(doseAgreement/100*slc1M(calcSlcIndV)').^2);
            tmpGammaV = bsxfun(@plus, tmpGammaV, (xysq + zV(slcCount)^2) / distAgreement^2);
        end
        gammaV(calcSlcIndV) = min(gammaV(calcSlcIndV),min(tmpGammaV));
        gammaM(:,:,slcNum) = reshape(gammaV,siz);
        slcCount = slcCount + 1;
    end
    if ~isempty(gammaGUIFig)
        set(ud.wb.patch,'xData',[0 0 slcNum/numSlices slcNum/numSlices])
        drawnow
    end    
end
gammaM = gammaM.^0.5;
toc
if ~isempty(gammaGUIFig)
    set(ud.wb.patch,'xData',[0 0 1 1])
end


