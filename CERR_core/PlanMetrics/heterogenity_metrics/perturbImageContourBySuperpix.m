function newMask3M = perturbImageContourBySuperpix(mask3M,img3M,superPixVol,varargin)
% function newMaskM = perturbImageContourBySuperpix(mask3M,img3M,voxelVol,superPixVol,varargin)
%
% Perturbs segmentation using SLIC superpixels.
%
% Example;
% superPixVol = 0.005;
% img3M = double(planC{indexS.scan}(1).sacnArray) -
% planC{indexS.scan}(1).scanInfo(1).CTOffset;
% mask3M = getUniformStr(1,planC);
% newMask3M =
% perturbImageContourBySuperpix(mask3M,img3M,superPixVol,planC);
%
% APA, 2/25/2019

% Determine the voxel volume
if iscell(varargin{1}) 
    planC = varargin{1};
    indexS = planC{end};
    scanNum = varargin{2};
    expansionRadius = 0.25; %cm (user input?)
    dy = planC{indexS.scan}(scanNum).scanInfo(1).grid1Units;
    dx = planC{indexS.scan}(scanNum).scanInfo(1).grid2Units;
    zV = [planC{indexS.scan}(scanNum).scanInfo(:).zValue];
    dz = mode(diff(zV));    
    voxelVol = dy * dx * dz;
else
    dx = planC(1);
    dy = planC(2);
    dz = planC(3);
    voxelVol = dy * dx * dz;
end

% Determine the expansion radius
sizV = size(img3M);
iExpand = round(expansionRadius/dy);
jExpand = round(expansionRadius/dx);
kExpand = round(expansionRadius/dz);

% Determine i/j/k for bounding box
[iV,jV,kV] = find3d(mask3M);
iMin = max(1,min(iV)-iExpand);
iMax = min(sizV(1),max(iV)+iExpand);
jMin = max(1,min(jV)-jExpand);
jMax = min(sizV(2),max(jV)+jExpand);
kMin = max(1,min(kV)-kExpand);
kMax = min(sizV(3),max(kV)+kExpand);

% Crop image and mask
maskM = mask3M(iMin:iMax,jMin:jMax,kMin:kMax);
imgM = img3M(iMin:iMax,jMin:jMax,kMin:kMax);

% Clip image intensities to focus on intensities within the contour mask
imgV = imgM(maskM);
minIntensity = min(imgV);
maxIntensity = max(imgV);
imgM(imgM < minIntensity) = minIntensity;
imgM(imgM > maxIntensity) = maxIntensity;

% Create superpixels
numVox = numel(maskM);
numSupPxl = round(voxelVol * numVox / superPixVol);
[superLablM,numSupPxlCalc] = superpixels3(imgM,numSupPxl);

% Get Surface mask
surfPtsM = getSurfacePoints(maskM);
surfMaskM = false(size(maskM));
for i=1:size(surfPtsM,1)
    surfMaskM(surfPtsM(i,1),surfPtsM(i,2), surfPtsM(i,3)) = true;
end

% Find intersection of superpixels with original ROI boundary
% activeSuperVoxV = false(numSupPxlCalc,1);
% for i = 1:numSupPxlCalc
%    if any(surfMaskM(superLablM(:)==i))
%        activeSuperVoxV(i) = true;
%    end
% end
% activeSuperVoxV = find(activeSuperVoxV);

activeSuperVoxV = unique(superLablM(surfMaskM));
numSuperVox = length(activeSuperVoxV);
randSuperVoxV = activeSuperVoxV(rand(numSuperVox,1) >= 0.5);

% Create the new mask
newMaskM = maskM;
for i = 1:length(activeSuperVoxV)
    labl = activeSuperVoxV(i);
    newMaskM = newMaskM & ~(superLablM == labl);
end

% newMaskM = false(size(maskM));
for i = 1:length(randSuperVoxV)
    labl = randSuperVoxV(i);
    newMaskM = newMaskM | superLablM == labl;
end

% Closing operation
se = strel('disk',5);
% windowSize = 11;
% kernel = ones(windowSize) / windowSize ^ 2;
for i = 1:size(newMaskM,3)
    slcM = maskM(:,:,i);
    newSlcM = newMaskM(:,:,i);
    cc = bwconncomp(newSlcM,4);
    for iComp = 1:cc.NumObjects
        if all(slcM(cc.PixelIdxList{iComp}))
            newSlcM(cc.PixelIdxList{iComp}) = 1;
        end
        if all(~slcM(cc.PixelIdxList{iComp}))
            newSlcM(cc.PixelIdxList{iComp}) = 0;
        end
    end
    newSlcM = imclose(newSlcM,se);
    %blurryImage = conv2(single(newSlcM), kernel, 'same');
    %newSlcM = blurryImage > 0.5; % Rethreshold
    
    newMaskM(:,:,i) = newSlcM;
end

% Fill the full mask
newMask3M = false(size(mask3M));
newMask3M(iMin:iMax,jMin:jMax,kMin:kMax) = newMaskM;
