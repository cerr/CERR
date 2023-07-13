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

% Get row & col indices of base scan
indexS = planC{end};
basePositionMatrix = planC{indexS.scan}(scanNum).Image2PhysicalTransM * 10; %Convert to mm
baseSizV = size(planC{indexS.scan}(scanNum).scanArray);
[rowM,colM] = meshgrid(1:baseSizV(1), 1:baseSizV(2));
rowColM = [rowM(:),colM(:)] - 1;

% Initialize X,Y,Z output
onesV = ones(size(rowColM,1),1);
numSlcVoxels = length(onesV);
xyzM = zeros(numSlcVoxels*baseSizV(3),4);

for slc = 1:baseSizV(3)

    rowDeformM = rcs4M(:,:,slc,1);
    colDeformM = rcs4M(:,:,slc,2);
    slcDeformM = rcs4M(:,:,slc,3);
    dvfM = [rowDeformM(:), colDeformM(:), slcDeformM(:),0*onesV];

    rowColSlcM = [rowColM,onesV*(slc-1),onesV];
    rowColSlcDeformedM = rowColSlcM + dvfM;
    xyzM(1+(slc-1)*numSlcVoxels:slc*numSlcVoxels,1:4) = (basePositionMatrix * rowColSlcM')';

    xyzDeformedM(1+(slc-1)*numSlcVoxels:slc*numSlcVoxels,1:4) = (basePositionMatrix * rowColSlcDeformedM')';
end

dvfXYZM = xyzDeformedM - xyzM;     % size of dvfXYZM will be nVoxels x 4

%reshape dvfXYZM to xyz4M
xyz4M = reshape(dvfXYZM(:,1:3),[baseSizV(1:3),3]);

