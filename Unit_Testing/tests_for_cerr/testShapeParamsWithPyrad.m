% this script tests shape features between CERR and pyradiomics.
%
% RKP, 03/22/2018



% % Structure from planC
% global planC
% indexS = planC{end};
% scanNum     = 1;
% structNum   = 16;
% 
% [rasterSegments, planC, isError]    = getRasterSegments(structNum,planC);
% [mask3M, uniqueSlices]              = rasterToMask(rasterSegments, scanNum, planC);
% scanArray3M                         = getScanArray(planC{indexS.scan}(scanNum));
% 
% SUVvals3M                           = mask3M.*double(scanArray3M(:,:,uniqueSlices));
% [minr, maxr, minc, maxc, mins, maxs]= compute_boundingbox(mask3M);
% maskBoundingBox3M                   = mask3M(minr:maxr,minc:maxc,mins:maxs);
% volToEval                           = SUVvals3M(minr:maxr,minc:maxc,mins:maxs);
% volToEval(maskBoundingBox3M==0)     = NaN;
% 
% testM = imquantize_cerr(volToEval,nL);

numRows = 100;
numCols = 100;
numSlcs = 100;

% Random n x n x n matrix 
testM = rand(numRows,numCols,numSlcs);

xV = 1:numCols;
yV = 1:numRows;
zV = 1:numSlcs;

%generating ellipsoid shape
xc = 50;
yc = 30;
zc = 45;
xr = 20;
yr = 30;
zr = 10;
[xM,yM,zM] = meshgrid(xV,yV,zV);

mask3M = ((xM-xc)./xr).^2 + ((yM-yc)./yr).^2 + ((zM-zc)./zr).^2 <= 1;


%generate results from pyradiomics
teststruct = PyradWrapper(testM, mask3M);


%% CERR Shape features


shapeS = getShapeParams(mask3M,{xV,yV,zV});

cerrShapeV = [shapeS.majorAxis, shapeS.minorAxis, shapeS.leastAxis, ...
    shapeS.flatness, shapeS.elongation, shapeS.max3dDiameter, shapeS.max2dDiameterAxialPlane,...
    shapeS.max2dDiameterSagittalPlane', shapeS.max2dDiameterCoronalPlane, ...
    shapeS.Compactness1, shapeS.Compactness2, shapeS.spherDisprop, ...
    shapeS.sphericity, shapeS.surfToVolRatio/10,...
    shapeS.surfArea*100, shapeS.volume*1000];
pyradShapeNamC = {'MajorAxis', 'MinorAxis', 'LeastAxis', 'Flatness',  'Elongation', ...
    'Maximum3DDiameter', 'Maximum2DDiameterSlice', 'Maximum2DDiameterRow', ...
    'Maximum2DDiameterColumn', 'Compactness1','Compactness2','spherDisprop','Sphericity', ...
    'SurfaceVolumeRatio','SurfaceArea','Volume'};
pyradShapeNamC = strcat(['original','_shape_'],pyradShapeNamC);
pyRadShapeV = [];
for i = 1:length(pyradShapeNamC)
    if isfield(teststruct,pyradShapeNamC{i})
        pyRadShapeV(i) = teststruct.(pyradShapeNamC{i});
    else
        pyRadShapeV(i) = NaN;
    end
end
shapeDiffV = (cerrShapeV - pyRadShapeV) ./ cerrShapeV * 100
