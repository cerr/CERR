function newMaskM = perturbImageContourBySuperpix(mask3M,img3M,voxelVol,superPixVol)
% function newMaskM = perturbImageContourBySuperpix(mask3M,img3M,voxelVol,superPixVol)
%
% Perturbs segmentation using SLIC superpixels.
%
% APA, 2/25/2019

%superPixVol = 0.05;
dy = planC{indexS.scan}.scanInfo(1).grid1Units;
dx = planC{indexS.scan}.scanInfo(1).grid2Units;
dz = planC{indexS.scan}.scanInfo(2).zValue - planC{indexS.scan}.scanInfo(1).zValue;
voxelVol = dy * dx * dz;    

sizV = size(img3M);
expansionRadius = 0.25; %cm
iExpand = round(expansionRadius/dy);
jExpand = round(expansionRadius/dx);
kExpand = round(expansionRadius/dz);

slc = 30;

[iV,jV,kV] = find3d(mask3M);
iMin = max(1,min(iV)-iExpand);
iMax = min(sizV(1),max(iV)+iExpand);
jMin = max(1,min(jV)-jExpand);
jMax = min(sizV(2),max(jV)+jExpand);
kMin = max(1,min(kV)-kExpand);
kMax = min(sizV(3),max(kV)+kExpand);

maskM = mask3M(iMin:iMax,jMin:jMax,kMin:kMax);
imgM = img3M(iMin:iMax,jMin:jMax,kMin:kMax);

numVox = numel(maskM);
numSupPxl = round(voxelVol * numVox / superPixVol);
[superLablM,numLabels] = superpixels3(imgM,numSupPxl);

overlapSuperVoxlV = unique(superLablM(maskM));
intersectV = zeros(size(overlapSuperVoxlV));
for i = 1:length(overlapSuperVoxlV)
   labl = overlapSuperVoxlV(i);
   intersectV(i) = sum(maskM(:) & superLablM(:) == labl) / sum(superLablM(:) == labl);
end



