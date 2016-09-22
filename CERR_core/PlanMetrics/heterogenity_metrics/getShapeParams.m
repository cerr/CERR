% getShapeParams.m

% APA, 07/06/2016

global planC
indexS = planC{end};

% define structure number
structNum = 33;

% Get associated scan
scanNum = getStructureAssociatedScan(structNum,planC);

% Get surface points
[xVals, yVals, zVals] = getUniformScanXYZVals(planC{indexS.scan}(scanNum));
mask3M = getUniformStr(structNum);
surfPoints = getSurfacePoints(mask3M);
xSurfV = xVals(surfPoints(:,2));
ySurfV = yVals(surfPoints(:,1));
zSurfV = zVals(surfPoints(:,3));

% Generate surfacemesh
triMesh = delaunay(xSurfV,ySurfV,zSurfV);
TR = triangulation(triMesh, xSurfV', ySurfV', zSurfV');
[tri, Xb] = freeBoundary(TR);

% plot surface
figure, trisurf(tri, Xb(:,1), Xb(:,2), Xb(:,3), 'EdgeColor', 'cyan',...
    'FaceColor', 'cyan','FaceAlpha', 0.2);

% Calculate surface area from triangular mesh
area = trimeshSurfaceArea(Xb,tri);

% Calculate Volume of the structure
vol = getStructureVol(structNum, planC);

% Compactness 1 (V/(pi*A^(3/2)), eq. (15) Aerts Nature suppl.
Compactness1 = vol / (pi*area^1.5);

% Compactness 2 (36*pi*V^2/A^3), eq. (16) Aerts Nature suppl.
Compactness2 = 36*pi*vol^2/area^3;

% max3dDiameter , eq. (17) Aerts Nature suppl.

% Spherical disproportion (A/(4*pi*R^2) , eq. (18) Aerts Nature suppl.
R = (vol*3/4/pi)^(1/3);
spherDisprop = area / (4*pi*R^2);

% Sphericity , eq. (19) Aerts Nature suppl.
sphericity = pi^(1/3) * (6*vol)^(2/3) / area;

% Surface area , eq. (20) Aerts Nature suppl.

% Surface to volume ratio , eq. (21) Aerts Nature suppl.
surfToVolRatio = area / vol;

% volume , eq. (22) Aerts Nature suppl.
vol;





