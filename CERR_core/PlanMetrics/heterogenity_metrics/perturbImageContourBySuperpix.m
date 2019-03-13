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
    dx = planC(2);
    dx = planC(3);
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
imgM(imgM > minIntensity) = maxIntensity;

% Create superpixels
numVox = numel(maskM);
numSupPxl = round(voxelVol * numVox / superPixVol);
superLablM = superpixels3(imgM,numSupPxl);

% Find intersection with original ROI
overlapSuperVoxlV = unique(superLablM(maskM));
intersectV = zeros(size(overlapSuperVoxlV));
for i = 1:length(overlapSuperVoxlV)
   labl = overlapSuperVoxlV(i);
   intersectV(i) = sum(maskM(:) & superLablM(:) == labl) / sum(superLablM(:) == labl);
end

% generate random numbers to select 0.2 <= superpixels < 0.9
unifRandV = rand(size(intersectV));

% Select superpixels
labelKeepV = intersectV >= 0.9;
labelRemV = intersectV < 0.2;
toChooseV = intersectV < 0.9 & intersectV >= 0.2 & unifRandV <= intersectV;

labelKeepV = labelKeepV | toChooseV;
labelstoKeepV = overlapSuperVoxlV(labelKeepV);

% Create the new mask
newMaskM = false(size(maskM));
for i = 1:length(labelstoKeepV)
    labl = overlapSuperVoxlV(i);
    newMaskM = newMaskM | superLablM == labl;
end

% Closing operation
se = strel('arbitrary',ones(3));
for i = 1:size(newMaskM,3)
    newMaskM(:,:,i) = imclose(newMaskM(:,:,i),se);
end

% Fill the full mask
newMask3M = false(size(mask3M));
newMask3M(iMin:iMax,jMin:jMax,kMin:kMax) = newMaskM;
