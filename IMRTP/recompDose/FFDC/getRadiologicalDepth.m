function radDepthV = getRadiologicalDepth(xV, yV, zV, gantryAngle, isocenter, isodistance, structNum, scanSet, planC)
%"getRadiologicalDepth"
%   Returns the radiological depth at the points in xV, yV, zV, as
%   determined from scanSet with a point source at sourceV.  structNum
%   tells the interpolation routine to only include the densities of 
%   points within a certain structure when calculating the radiological
%   depth.
%
%JRA 06/16/05
%
%Usage:
%  function radDepthV = getRadiologicalDepth(xV, yV, zV, gA, iC, iD, structNum, scanSet, planC)
%
% Copyright 2010, Joseph O. Deasy, on behalf of the CERR development team.
% 
% This file is part of The Computational Environment for Radiotherapy Research (CERR).
% 
% CERR development has been led by:  Aditya Apte, Divya Khullar, James Alaly, and Joseph O. Deasy.
% 
% CERR has been financially supported by the US National Institutes of Health under multiple grants.
% 
% CERR is distributed under the terms of the Lesser GNU Public License. 
% 
%     This version of CERR is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
% CERR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
% without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with CERR.  If not, see <http://www.gnu.org/licenses/>.

if ~exist('planC')
    global planC
end
indexS = planC{end};

siz = size(xV);

%Get mask of requested structure.
rS = getRasterSegments(structNum, planC);
[structMask, slicesV] = rasterToMask(rS, scanSet, planC); 
% rS = getRasterSegments(structNum, planC);
% [structMask, slicesV] = rasterToMask(rS, scanSet, planC);  
% [surfPoints] = getSurfacePoints(structMask);

%Get coordinates of scan voxels inside the structure.
[xS, yS, zS] = getScanXYZVals(planC{indexS.scan}(scanSet));
[xM, yM, zM] = meshgrid(xS, yS, zS(slicesV));
xM = xM(structMask);
yM = yM(structMask);
zM = zM(structMask);
% [xS, yS, zS] = getScanXYZVals(planC{indexS.scan}(scanSet));
% zS = zS(slicesV);
% xM = xS(surfPoints(:,1));
% yM = yS(surfPoints(:,2));
% zM = zS(surfPoints(:,3));
% clear surfPoints

%Convert points to collimator coordinates.
coll3V = scan2Collimator([xM(:) yM(:) zM(:)], gantryAngle, 0, 0, isocenter, isodistance);
clear xM yM zM;

%Get distance from source to all points.
distsquared = sepsq(coll3V', [0 0 0]');

%Project vector to points to the perpendicular plane at isocenter.
coll3V = coll3V./repmat(coll3V(:,3), [1 3]) * -isodistance;

%Find the extents of X,Y,D for the region covering the structure (ie, all
%nonzero scan numbers since we will set scan densities outside of structure
%to be 0.
minExt = min(coll3V);
maxExt = max(coll3V);
clear coll3V;

minProjX = minExt(1);
maxProjX = maxExt(1);

minProjY = minExt(2);
maxProjY = maxExt(2);

maxDsq = max(distsquared);
minDsq = min(distsquared);
clear distsquared;

%Set points in scanArray outside of structure to 0.
sA = planC{indexS.scan}(scanSet).scanArray;
for i=1:size(sA, 3);    
    [ismem, loc] = ismember(i, slicesV);
    if ismem
        slc = sA(:,:,i);
        slc(~structMask(:,:,loc)) = 0;
        sA(:,:,i) = slc;
    else
        sA(:,:,i) = zeros(size(sA(:,:,i)));    
    end
end    
clear structMask;

%Convert requested points to collimator coordinates.
coll3V = scan2Collimator([xV(:) yV(:) zV(:)], gantryAngle, 0, 0, isocenter, isodistance);
clear xM yM zM;

%Get distance from source to all requested points.
distsquared = sepsq(coll3V', [0 0 0]');

%Project vector to points to the perpendicular plane at isocenter.
coll3V = coll3V./repmat(coll3V(:,3), [1 3]) * -isodistance;

clear xV yV zV

%Find out of bounds points, for which calculation is not necessary,
%radDepth is zero.
OOBPoints = coll3V(:,1) < minProjX | coll3V(:,1) > maxProjX | coll3V(:,2) < minProjY | coll3V(:,2) > maxProjY;

%Clip the r values so they take the density of the nearest calculated
%point (points less than minDsq would take zero, and greater than maxDsq
%would take the last radDepthV value along that ray.
r = clip(distsquared, minDsq, maxDsq, 'limits');

%Set the resolution of the radiological depth calculation (at isocenter).
dX = .5;
dY = .5;
dR = .25;

%Mesh the radiological depth calculation grid in collimator coordinates.
projXV = minProjX:dX:maxProjX;
projYV = minProjY:dY:maxProjY;
distV = sqrt(minDsq):dR:sqrt(maxDsq);
[projXVM, projYVM, distVM] = meshgrid(projXV, projYV, distV);

projDistV = sqrt(sepsq([projXVM(:) projYVM(:) -isodistance*ones(size(projXVM(:)))]', [0 0 0]'));
projXVM = projXVM(:) .* (distVM(:) ./ projDistV);
projYVM = projYVM(:) .* (distVM(:) ./ projDistV);
projZVM = -isodistance*ones(size(distVM(:))) .* (distVM(:) ./ projDistV);

%Convert the depth calculation grid to rectangular coordinates.
newXYZ = collimator2Scan([projXVM(:) projYVM(:) projZVM(:)], gantryAngle, 0, 0, isocenter, isodistance);
% clear projXVM projYVM distVM

%Get the scan values at each point in the radiological depth grid.
[xVS, yVS, zVS] = getScanXYZVals(planC{indexS.scan}(scanSet));

%Interpolate to values in xV/yV/zV from the scanarray, 0 if out of bounds.
scanVals = finterp3(newXYZ(:,1), newXYZ(:,2), newXYZ(:,3), sA, [xVS(1) xVS(2)-xVS(1) xVS(end)], [yVS(1) yVS(2)-yVS(1) yVS(end)], zVS, 0);

scanVals = reshape(scanVals, length(projXV), length(projYV), length(distV));

%Scale values by the resolution of R to get the linear radiological depth.
%Divide by 1024 to get the radiological depth in units of water.
scanVals = scanVals .* (dR / 1024);

%Take the cumsum to get the actual radiological depth at each point in the
%depth calculation grid.
cumDens = cumsum(scanVals, 3);
clear scanVals

cumDens = reshape(cumDens, size(distVM));

%Interpolate to values in xV/yV/zV from the scanarray, 0 if out of bounds.
radDepthV = finterp3(coll3V(:,1), coll3V(:,2), sqrt(distsquared), cumDens, [projXV(1) projXV(2)-projXV(1) projXV(end)], [projYV(1) projYV(2)-projYV(1) projYV(end)], distV, 0);

radDepthV(OOBPoints) = 0;
radDepthV = reshape(radDepthV, siz);