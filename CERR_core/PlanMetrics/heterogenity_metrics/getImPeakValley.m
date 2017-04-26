function featureS = getImPeakValley(structNum, scanNum, radius, radiusUnit, planC)
% function featureS = getImPeakValley(structNum, scanNum, radiusV, radiusUnit, planC)
%
% This function computes the mean intensity around the tallest peak and the
% lowest valley within the passed structure.

%
% INPUTS:
% structNum:  Structure index within planC or 3d structure mask of 0s and 1s
% scanNum:    Scan index within planC or 3d scan matrix
% radius:     The neighborhood radius to compute mean. 
%             If radiusUnit is 'cm' radius is a scalar value. 
%             If radiusUnit is 'vox', radius is a 3-element vector 
%             specifying the number of voxels along the columns, rows and 
%             slices in that order. radius must be a vector of integers if 
%             radiusUnit is 'cm' 
% radiusUnit: 'cm' or 'vox'
%
% APA, 04/07/2017

if ~exist('planC','var')
    scan3M = scanNum;
    struct3M = structNum;
    nx = radius(1);
    ny = radius(2);
    nz = radius(3);    
else
    indexS = planC{end};
    [rasterSegments, planC, isError]    = getRasterSegments(structNum,planC);
    [mask3M, uniqueSlices]              = rasterToMask(rasterSegments, scanNum, planC);
    scanArray3M                         = getScanArray(planC{indexS.scan}(scanNum));
    scanArray3M = double(scanArray3M) - planC{indexS.scan}(scanNum).scanInfo(1).CTOffset;
    
    scan3M = mask3M.*double(scanArray3M(:,:,uniqueSlices));
    [minr, maxr, minc, maxc, mins, maxs]= compute_boundingbox(mask3M);
    struct3M = mask3M(minr:maxr,minc:maxc,mins:maxs);
    scan3M = scan3M(minr:maxr,minc:maxc,mins:maxs);
    
    if strcmpi(radiusUnit,'cm')
        [xV,yV,zV] = getScanXYZVals(planC{indexS.scan}(scanNum));
        dx = abs(xV(1) - xV(2));
        dy = abs(yV(1) - yV(2));
        dz = abs(zV(1) - zV(2));     
        nx = round(radius / dx);
        ny = round(radius / dy);
        nz = round(radius / dz);
    else
        nx = radius(1);
        ny = radius(2);
        nz = radius(3);
    end
end

if ~isequal(radius, uint16(radius))
    error('Radius must be an integer')
end

% x = 1; % cm
% dx = 1;
% dy = 1;
% dz = 1;
% nx = round(x / dx); % columns
% ny = round(x / dy); % rows
% nz = round(x / dz); % slices

% Build a spherical neighborhood
sphereM = ones(2*ny+1,2*nx+1,2*nz+1);
rowsM = repmat((1:2*ny+1)', [1, size(sphereM,2), size(sphereM,3)]);
colsM = repmat(1:2*nx+1, [size(sphereM,1), 1, size(sphereM,3)]);
slcsM = zeros(size(sphereM));
for i = 1:size(sphereM,3)
    slcsM(:,:,i) = i;
end
cC = nx + 1;
rC = ny + 1;
sC = nz + 1;
distM = (rowsM - rC).^2/ny^2 + (colsM - cC).^2/nx^2 + (slcsM - sC).^2/nz^2;
sphereM(distM > 1) = 0;

% Convolve neighborhood on the entire scan and the structure mask
scan3M(~struct3M) = 0;
sumM = convn(scan3M,sphereM,'same');
numVoxM = convn(struct3M,sphereM,'same');

% Compute average per voxel
avgM = sumM ./ numVoxM;

% Get peak and valley
featureS.peak = max(avgM(:));
featureS.valley = min(avgM(:));
featureS.radius = radius;
featureS.radiusUnit = radiusUnit;

