function [slc, slcRowV, slcColV] = slice3DVol(data3M, xV, yV, zV, coord, dim, interpMtd, transM, compareMode, sliceXVals, sliceYVals)
%"slice3DVol"
%   Return a slice of a 3D dataset, cut along the x, y, or z axis at a
%   specified coordinate.  data3M is the full dataset and xV, yV, zV are
%   the coordinates of the columns, rows and slices of the dataset in
%   space.
%
%   dim is the dimension to slice in, where x=1, y=2, z=3.  Coord is the
%   position in space where the slice is taken in the specified dim.
%
%   interpMtd is an optional string specifying the interpolation method to
%   use.  'nearest' or 'linear' are supported.
%
%   transM is an optional 4x4 transformation matrix to be applied to the data
%   before slicing.  This allows for arbitrary slices or slicing of datasets
%   that have been rotated and registered.
%
%   Output is a slice and two vectors giving the coordinates of the rows
%   and columns of the slice.
%
%   JRA 01/03/05
% LM DK 05/11/06 Added dose comparemode dose calculation for
% 'RELMAXPRODIFF';'RELMINPRODIFF';'ABSMAXPRODIFF';'ABSMINPRODIFF' cases
%Usage:
%   function [slc, slcRowV, slcColV] = slice3DVol(data3M, xV, yV, zV, coord, dim, interpMtd, transM)
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


%Figure out which spatial dimension is in the image's X and Y direction.
switch dim
    case 1
        imageXDim = 2;
        imageYDim = 3;
    case 2
        imageXDim = 1;
        imageYDim = 3;
    case 3
        imageXDim = 1;
        imageYDim = 2;
end

xLims = [xV(1) xV(end)];
yLims = [yV(1) yV(end)];
zLims = [zV(1) zV(end)];

%Check for transM, and if it has any rotation component.
rotation = 0; xT = 0; yT = 0; zT = 0;
if exist('transM') && ~isempty(transM) && ~isequal(transM, eye(4))
    [rotation, xT, yT, zT] = isrotation(transM);
end

if rotation
    %Get the corners of the original dataset.
    [xCorn, yCorn, zCorn] = meshgrid(xLims, yLims, zLims);

    %Add ones to the corners so we can apply a transformation matrix.
    corners = [xCorn(:) yCorn(:) zCorn(:) ones(prod(size(xCorn)), 1)];

    %Apply transform to corners, so we know boundary of the slice.
    newCorners = transM * corners';
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

%If we are outside the range of the transformed dataset, return empty.
if coord < min(XYZLims{dim}) | coord > max(XYZLims{dim})
    slc = []; slcRowV = []; slcColV = [];
    return;
end

if ~exist('sliceXVals','var')
    %Mesh the rotated limits to get x,y of new slice.  Use original image res.
    % sliceXVals = linspace(XYZLims{imageXDim}(1), XYZLims{imageXDim}(2), XYZRes{imageXDim});
    % sliceYVals = linspace(XYZLims{imageYDim}(1), XYZLims{imageYDim}(2), XYZRes{imageYDim});
    sliceXVals = linspace(XYZLims{imageXDim}(1), XYZLims{imageXDim}(2), 256);
    sliceYVals = linspace(XYZLims{imageYDim}(1), XYZLims{imageYDim}(2), 256);
else
    %Assume x,y,z grid is different.
    rotation = 1;
end

%Perform rotation and return slice, if rotation is required.
if rotation

    %Get required mesh values, and set other parameters specific to dim.
    switch dim
        case 1
            [xM, yM, zM] = meshgrid(coord, sliceXVals, sliceYVals);
            imgSize      = [1 length(sliceXVals) length(sliceYVals)];
            permuteM     = [3 2 1];
        case 2
            [xM, yM, zM] = meshgrid(sliceXVals, coord, sliceYVals);
            imgSize      = [length(sliceXVals) 1 length(sliceYVals)];
            permuteM     = [3 1 2];
        case 3
            [xM, yM, zM] = meshgrid(sliceXVals, sliceYVals, coord);
            imgSize      = [length(sliceYVals) length(sliceXVals) 1];
            permuteM     = [1 2 3];
    end

    %Apply transformation to the limits if necessary.
    if exist('transM')
        mat = [xM(:) yM(:) zM(:) ones(prod(size(xM)), 1)]';
        mat = inv(transM) * mat;
        xM = mat(1,:);
        yM = mat(2,:);
        zM = mat(3,:);
    end

    %Find corners of scan data included in this slice.
    [minX, jnk] = findnearest(xV, min(xM(:)));
    [jnk, maxX] = findnearest(xV, max(xM(:)));
    [minY, jnk] = findnearest(yV, min(yM(:)));
    [jnk, maxY] = findnearest(yV, max(yM(:)));
    [minZ, jnk] = findnearest(zV, min(zM(:)));
    [jnk, maxZ] = findnearest(zV, max(zM(:)));

    %Take care of numerical noise
    delta = 1e-5;
    %Prepare the x,y,z vector inputs for finterp3.
    xVec = [xV(minX)-delta xV(2)-xV(1) xV(maxX)+delta];
    yVec = [yV(minY)-delta yV(2)-yV(1) yV(maxY)+delta];
    
    if length(minZ:maxZ)==1 && minZ==maxZ 
        minZ = max(1,minZ-1);
        maxZ = min(maxZ+1,length(zV));
    end
    zVec = zV(minZ:maxZ);

    %Interpolate to get slice.
    slc = finterp3(xM(:), yM(:), zM(:), data3M(maxY:minY, minX:maxX, minZ:maxZ), xVec, fliplr(yVec), zVec, 0);

    slcRowV = sliceYVals;
    slcColV = sliceXVals;

    %Reshape the linear slice to 2D. Permute to get proper orientation.
    slc = reshape(slc, imgSize);
    slc = permute(slc, permuteM);
    slc = squeeze(slc);

else %Rotation is not required, simply return a standard slice with shifted xV,yV,zV.
    xV = xV + xT;
    yV = yV + yT;
    zV = zV + zT;

    [slc, slcRowV, slcColV] = slice3DVolOrtho(data3M, xV, yV, zV, coord, dim, interpMtd);

    slc = squeeze(slc);
end
% DK
% compareModes =
% ['RELMAXPRODIFF';'RELMINPRODIFF';'ABSMAXPRODIFF';'ABSMINPRODIFF'];
if ~isempty(compareMode)
    switch upper(compareMode)
        case 'RELDIFF'
            %do nothing
        case {'RELMAXPRODIFF','ABSMAXPRODIFF'}
            slc =  max(data3M, [], dim);
        case {'RELMINPRODIFF','ABSMINPRODIFF'}
            slc = min(data3M, [], dim);
        case {'ABSDIFF','ABSMAXPRODIFF','ABSMINPRODIFF'}
            slc = abs(slc);
    end
end
% DK end
slc = double(slc);


function [slc, slcRowV, slcColV] = slice3DVolOrtho(data3M, xV, yV, zV, coord, dim, interpMtd)
%"slice3DVolOrtho"
%   Slice data3M in dimension dim at coordinate coord, without rotation.

switch dim
    case 1
        slice = interp1(xV, 1:length(xV), coord);
        %             slice = finterp1(xV, 1:length(xV), coord);
    case 2
        slice = interp1(yV, 1:length(yV), coord);
        %             slice = finterp1(yV, 1:length(yV), coord);
    case 3
        slice = interp1(zV, 1:length(zV), coord);
        %             slice = finterp1(zV, 1:length(zV), coord);
end

lowerSlcNum = floor(slice+1e-8);
upperSlcNum = ceil(slice-1e-8);
lowerSlcRatio = (upperSlcNum - slice);
upperSlcRatio = 1 - lowerSlcRatio;

switch dim
    case 1
        permuteM     = [3 2 1];
        lowerSlc = data3M(:,lowerSlcNum,:);
        upperSlc = data3M(:,upperSlcNum,:);
        slcColV = yV;
        slcRowV = zV;
    case 2
        permuteM     = [3 1 2];
        lowerSlc = data3M(lowerSlcNum,:,:);
        upperSlc = data3M(upperSlcNum,:,:);
        slcColV = xV;
        slcRowV = zV;
    case 3
        permuteM     = [1 2 3];
        lowerSlc = data3M(:,:,lowerSlcNum);
        upperSlc = data3M(:,:,upperSlcNum);
        slcColV = xV;
        slcRowV = yV;
end

if strcmpi(interpMtd, 'linear')
    slc = double(lowerSlc)*(lowerSlcRatio) + double(upperSlc)*(upperSlcRatio);
elseif strcmpi(interpMtd, 'nearest')
    if lowerSlcRatio > .5
        slc = lowerSlc;
    else
        slc = upperSlc;
    end
else
    error('Unknown interpolation method specified.')
end
slc = permute(slc, permuteM);
slc = squeeze(slc);
slc = double(slc);
