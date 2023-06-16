function xyz4M = dvfImageToDICOMCoords(rcs4M,scanNum,planC)
% Get physical (x,y,z) coordinates of scanNum in DICOM LPS from 
% deformation vector field inimage coordinates.
%
% Input: rcs4M - 4D-matrix containing row, col and slice coordinates of DFV
%        scanNum - base scan index on which DVF was derived
%        planC - CERR's planC data structure
% Output: xyz4M - (x,y,z) in DICOM LPS of the DVF
%
% APA, 6/16/2023

basePositionMatrix = planC{indexS.scan}(scanNum).Image2PhysicalTransM;
baseSizV = size(planC{indexS.scan}(scanNum).scanArray);
[rowM,colM] = meshgrid(1:baseSizV(1), 1:baseSizV(2));
rowColM = [rowM(:),colM(:)] - 1;
onesV = ones(size(rowColM,1),1);
numSlcVoxels = length(onesV);
xyzM = zeros(numSlcVoxels*baseSizV(3),4);
for slc = 1:baseSizV(3)
    rowColSlcM = [rowColM,onesV*(slc-1),onesV];
    rowColSlcDeformedM = rowColM + dvf;
    xyzM(1+(slc-1)*numSlcVoxels:slc*numSlcVoxels,1:4) = (basePositionMatrix * rowColSlcM')';
    xyzDeforedM(1+(slc-1)*numSlcVoxels:slc*numSlcVoxels,1:4) = (basePositionMatrix * rowColSlcDeformedM')';
    dvfXYZM = xyzDeforedM - xyzM; % size of dvfXYZM will be nVoxels x 4    
end

%reshape dvfXYZM to xyz4M
