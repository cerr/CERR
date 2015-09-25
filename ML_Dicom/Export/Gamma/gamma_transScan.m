function planC = gamma_transScan(planC, scanSet)
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

indexS = planC{end};

% Apply transformation to Scan
[xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(scanSet));

if isfield(planC{indexS.scan}(scanSet), 'transM') & ~isempty(planC{indexS.scan}(scanSet).transM);
    [rotation, xT, yT, zT] = isrotation(planC{indexS.scan}(scanSet).transM);
end

xLims = [xV(1) xV(end)];
yLims = [yV(1) yV(end)];
zLims = [zV(1) zV(end)];

if rotation
    %Get the corners of the original scan.
    [xCorn, yCorn, zCorn] = meshgrid(xLims, yLims, zLims);

    %Add ones to the corners so we can apply a transformation matrix.
    corners = [xCorn(:) yCorn(:) zCorn(:) ones(numel(xCorn), 1)];

    %Apply transform to corners, so we know boundary of the slice.
    newCorners = planC{indexS.scan}(scanSet).transM * corners';
    newXLims = [min(newCorners(1,:)) max(newCorners(1,:))];
    newYLims = [min(newCorners(2,:)) max(newCorners(2,:))];
    newZLims = [min(newCorners(3,:)) max(newCorners(3,:))];
else
    %No transform or simple translation.  New limits same as old.
    newXLims = xLims + xT;
    newYLims = yLims + yT;
    newZLims = zLims + zT;
end

XYZLims = {newXLims, newYLims, newZLims};
XYZRes  = {length(xV), length(yV), length(zV)};

imageXDim = 1; %X
imageYDim = 2; %Y
imageZDim = 3; %Z

%Mesh the rotated limits to get x,y of new slice. Use original image res
sliceXVals = linspace(XYZLims{imageXDim}(1), XYZLims{imageXDim}(2), XYZRes{imageXDim});
sliceYVals = linspace(XYZLims{imageYDim}(1), XYZLims{imageYDim}(2), XYZRes{imageYDim});
sliceZVals = linspace(XYZLims{imageZDim}(1), XYZLims{imageZDim}(2), XYZRes{imageZDim});

%New Scan dimentions
%%[xM, yM, zM] = meshgrid(sliceXVals, sliceYVals, 1);
[xM, yM, zM] = meshgrid(sliceXVals, sliceYVals, sliceZVals);
imgSize      = [length(sliceYVals) length(sliceXVals) length(sliceZVals)];

mat = [xM(:) yM(:) zM(:) ones(numel(xM), 1)]';
mat = inv(planC{indexS.scan}(scanSet).transM) * mat;
xM = mat(1,:);
yM = mat(2,:);
zM = mat(3,:);

clear mat

%Find corners of scan data included in this slice.
[minX, jnk] = findnearest(xV, min(xM(:)));
[jnk, maxX] = findnearest(xV, max(xM(:)));
[minY, jnk] = findnearest(yV, min(yM(:)));
[jnk, maxY] = findnearest(yV, max(yM(:)));
[minZ, jnk] = findnearest(zV, min(zM(:)));
[jnk, maxZ] = findnearest(zV, max(zM(:)));

%Need at least 2 Z slices.
if isequal(minZ, maxZ)
    maxZ = minZ+1;
end

%Prepare the x,y,z vector inputs for finterp3.
xVec = [xV(minX) xV(2)-xV(1) xV(maxX)];
yVec = [yV(maxY) yV(2)-yV(1) yV(minY)];
zVec = zV(minZ:maxZ);

%Make zMesh be all ones, to be multiplied by a zVal for each slice.
zMesh = ones(size(xM));

%Initialize the output variable.
data3M = repmat(uint16(zeros),[length(sliceYVals), length(sliceXVals), length(sliceZVals)]);

xM = reshape(xM,imgSize);
yM = reshape(yM,imgSize);
zM = reshape(zM,imgSize);

%Iterate over requested Z values and interpolate slice for each Z.
for i = 1:length(zV)
    slc = finterp3(xM(:,:,i), yM(:,:,i), zM(:,:,i), planC{indexS.scan}(scanSet).scanArray(maxY:minY,...
        minX:maxX, 1:length(zV)), xVec, yVec, zV,0);
    %         slc = reshape(slc, imgSize);
    %         slc = permute(slc, permuteM);
    %         data3M(:,:,i)= squeeze(slc);
    data3M(:,:,i)= slc;
end

clear xM yM zM zMesh xVec yVec zVec

data3M(isnan(data3M))=0;

data3M = flipdim(data3M,1);

planC{indexS.scan}(end+1) = planC{indexS.scan}(scanSet);

planC{indexS.scan}(end).scanArray = data3M;

clear data3M
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set scan coordinates back into the planC
midPointX = (length(sliceXVals)-1)/2;

lowLim = floor(midPointX); upLim = ceil(midPointX);

if lowLim == upLim
    xOffset = sliceXVals(midPointX);
else
    xOffset =(sliceXVals(upLim)+sliceXVals(lowLim))/2;
end

midPointY = (length(sliceYVals)-1)/2;

lowLim = floor(midPointY); upLim = ceil(midPointY);

if lowLim == upLim
    yOffset = sliceYVals(midPointY);
else
    yOffset =(sliceYVals(upLim)+sliceYVals(lowLim))/2;
end

[planC{indexS.scan}(end).scanInfo.grid2Units] = deal(sliceXVals(2)-sliceXVals(1));
[planC{indexS.scan}(end).scanInfo.xOffset] = deal(xOffset);

[planC{indexS.scan}(end).scanInfo.grid1Units] = deal(sliceYVals(2)-sliceYVals(1));
[planC{indexS.scan}(end).scanInfo.yOffset] = deal(yOffset);

[planC{indexS.scan}(end).scanInfo.sliceThickness] = deal(sliceZVals(2)- sliceZVals(1));

for i=1:length(sliceZVals)
    planC{indexS.scan}(end).scanInfo(i).zValue = sliceZVals(i);
end

clear sliceXVals sliceYVals sliceZVals

planC{indexS.scan}(end).scanUID = createUID('scan');

planC{indexS.scan}(end).transM = [];

planC{indexS.scan}(end).scanArrayInferior = [];
planC{indexS.scan}(end).scanArraySuperior = [];
planC{indexS.scan}(end).uniformScanInfo = [];

planC = setUniformizedData(planC);

% Set Dose Links to the new scan.
doseIndx = allLink_to_scan(planC, scanSet);

[planC{indexS.dose}(doseIndx).associatedScan] = deal(length(planC{indexS.scan}));

[planC{indexS.dose}(doseIndx).assocScanUID] = deal(planC{indexS.scan}(end).scanUID);

% Apply Transformation to Structures
[doseIndx structIndx]= allLink_to_scan(planC, scanSet);

% for structNum = 1: length(structIndx)
%     planC = copyStrToScan_meshBased(structIndx(structNum),length(planC{indexS.scan}),planC);
% end

% for structNum = 1: length(structIndx)
%     planC{indexS.structures}(structIndx(structNum)) = [];
% end

% Delete the Old scan
planC{indexS.scan}(scanSet) = [];
