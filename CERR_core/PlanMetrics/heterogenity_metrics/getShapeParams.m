function shapeS = getShapeParams(structNum,planC,rcsV)
% function shapeS = getShapeParams(structNum,planC,rcsV)
%
% This function computes shape features for the passed input.
%
% INPUTS:
% structNum: The structure index in planC
% planC: CERR's planC data structure
% rcsV: number of rows/colums/slices to use for resampling
%
% getShapeParams.m

% APA, 07/06/2016

if numel(structNum)
    if ~exist('planC','var')
        global planC
    end
    
    indexS = planC{end};
    
    % Get associated scan
    scanNum = getStructureAssociatedScan(structNum,planC);
    
    % Get surface points
    [xValsV, yValsV, zValsV] = getUniformScanXYZVals(planC{indexS.scan}(scanNum));
    yValsV = fliplr(yValsV);
    mask3M = getUniformStr(structNum,planC);
    
else
    mask3M = structNum;
    xValsV = planC{1};
    yValsV = planC{2};
    zValsV = planC{3};
    %voxelVol = 2; %abs((xVals(1)-xVals(2))*(yVals(1)-yVals(2))*(zVals(1)-zVals(2)));
    %volume = planC{4};
end

% Get voxel size
voxelSiz(1) = abs(yValsV(2) - yValsV(1));
voxelSiz(2) = abs(xValsV(2) - xValsV(1));
voxelSiz(3) = abs(zValsV(2) - zValsV(1));
voxelVolume = prod(voxelSiz);


volume = voxelVolume * sum(mask3M(:));

% Fill holes
mask3M = imfill(mask3M,'holes');
filledVolume = voxelVolume * sum(mask3M(:));

% Add a row/col/slice to account for half a voxel
mask3M = padarray(mask3M,[1 1 1],'replicate');
xValsV = [xValsV(1)-voxelSiz(1) xValsV xValsV(end)+voxelSiz(1)];
yValsV = [yValsV(1)-voxelSiz(2) yValsV yValsV(end)+voxelSiz(2)];
zValsV = [zValsV(1)-voxelSiz(3) zValsV zValsV(end)+voxelSiz(3)];

% Resample the structure mask
if exist('rcsV','var')
    % min/max voxel coordinates for resampling
    minX = min(xValsV)+voxelSiz(2)/2;
    maxX = max(xValsV)-voxelSiz(2)/2;
    minY = min(yValsV)+voxelSiz(1)/2;
    maxY = max(yValsV)-voxelSiz(1)/2;
    minZ = min(zValsV)+voxelSiz(3)/2;
    maxZ = max(zValsV)-voxelSiz(3)/2;
    % new x/y/z grid using the resampled size
    xValsNewV = linspace(minX,maxX,rcsV(2));
    yValsNewV = linspace(minY,maxY,rcsV(1));
    zValsNewV = linspace(minZ,maxZ,rcsV(3));
    [Xm,Ym,Zm] = meshgrid(xValsNewV,yValsNewV,zValsNewV);
    %xFieldV = [min(xValsV) max(xValsV)];
    %yFieldV = [min(yValsV) max(yValsV)];
    %zFieldV = [min(zValsV) max(zValsV)];
    %xyzUpC = {xValsNewV,yValsNewV,zValsNewV,volume};
    %outOfBoundsVal = 0;
    % resample the structure mask
    mask3M = interp3(xValsV, yValsV, zValsV, mask3M, Xm, Ym, Zm,'nearest');
    xValsV = xValsNewV;
    yValsV = yValsNewV;
    zValsV = zValsNewV;
end

% Get the surface points for the structure mask
surfPoints = getSurfacePoints(mask3M);
xSurfV = xValsV(surfPoints(:,2));
ySurfV = yValsV(surfPoints(:,1));
zSurfV = zValsV(surfPoints(:,3));

% Check if it's a coplanar structure
if length(unique(zSurfV)) < 2
    shapeS.surfArea = NaN;
    shapeS.vol = NaN;
    shapeS.Compactness1 = NaN;
    shapeS.Compactness2 = NaN;
    shapeS.spherDisprop = NaN;
    shapeS.sphericity = NaN;
    shapeS.surfToVolRatio = NaN;
    return;
end

% Generate surface mesh
triMesh = delaunay(xSurfV,ySurfV,zSurfV);
TR = triangulation(triMesh, xSurfV', ySurfV', zSurfV');
[tri, Xb] = freeBoundary(TR);

% % plot surface
% figure, trisurf(tri, Xb(:,1), Xb(:,2), Xb(:,3), 'EdgeColor', 'cyan',...
%     'FaceColor', 'cyan','FaceAlpha', 0.2);

% Calculate surface area from triangular mesh
shapeS.surfArea = trimeshSurfaceArea(Xb,tri);

% Calculate Volume of the structure, eq. (22) Aerts Nature suppl.
% if ndims(structNum) == 1
%     shapeS.vol = getStructureVol(structNum, planC);
% else
%     shapeS.vol = volume; %sum(mask3M(:)) * voxelVol;
% end
shapeS.volume = volume;
shapeS.filledVolume = filledVolume;

% Compactness 1 (V/(pi*A^(3/2)), eq. (15) Aerts Nature suppl.
shapeS.Compactness1 = shapeS.volume / (pi*shapeS.surfArea^1.5);

% Compactness 2 (36*pi*V^2/A^3), eq. (16) Aerts Nature suppl.
shapeS.Compactness2 = 36*pi*shapeS.volume^2/shapeS.surfArea^3;

% max3dDiameter , eq. (17) Aerts Nature suppl.

% Spherical disproportion (A/(4*pi*R^2) , eq. (18) Aerts Nature suppl.
R = (shapeS.volume*3/4/pi)^(1/3);
shapeS.spherDisprop = shapeS.surfArea / (4*pi*R^2);

% Sphericity , eq. (19) Aerts Nature suppl.
shapeS.sphericity = pi^(1/3) * (6*shapeS.volume)^(2/3) / shapeS.surfArea;

% Surface area , eq. (20) Aerts Nature suppl.

% Surface to volume ratio , eq. (21) Aerts Nature suppl.
shapeS.surfToVolRatio = shapeS.surfArea / shapeS.volume;


