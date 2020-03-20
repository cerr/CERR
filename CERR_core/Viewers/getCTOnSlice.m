function [slc, sliceXVals, sliceYVals, planC] = getCTOnSlice(scanSet, coord, dim, planC)
%"getCTOnSlice"
%   Returns the CT values on a slice in dimension dim.  If the CT has a
%   transformation matrix transM associated with it, the slice returned is
%   that of the transformed CT.
%
%   slc is a 2D matrix, but its voxel size is not well defined.  The rotation
%   takes the original row/col of a slice image and rotates them, resulting
%   in a larger image with zeros padding at the corners.
%
%   sliceXVals and sliceYVals are the coordinates of the cols/rows of the
%   image respectively.
%
%   dim = 1, 2, 3 for x, y, z respectively.
%
%JRA 12/3/04
%
%Usage:
%   function [slc, sliceXVals, sliceYVals] = getCTOnSlice(scanSet, coord, dim, planC)
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

global stateS;
indexS = planC{end};

%Get the coordinates of the original scan.
[xV, yV, zV] = getScanXYZVals(planC{indexS.scan}(scanSet));

%Use scan access function in case of remote variables.
scanArray    = getScanArray(scanSet,planC);

%Figure out which spatial dimension is in the image's X and Y direction.
switch dim
    case 1
        imageXDim = 2; %Y
        imageYDim = 3; %Z
    case 2
        imageXDim = 1; %X
        imageYDim = 3; %Z
    case 3
        imageXDim = 1; %X
        imageYDim = 2; %Y
end

xLims = [xV(1) xV(end)];
yLims = [yV(1) yV(end)];
zLims = [zV(1) zV(end)];



%Check for transM, and if it has any rotation component.
rotation = 0; xT = 0; yT = 0; zT = 0;
if isfield(planC{indexS.scan}(scanSet), 'transM') & ~isempty(planC{indexS.scan}(scanSet).transM);
    [rotation, xT, yT, zT] = isrotation(planC{indexS.scan}(scanSet).transM);
end

if rotation
    %Get the corners of the original scan.
    [xCorn, yCorn, zCorn] = meshgrid(xLims, yLims, zLims);

    %Add ones to the corners so we can apply a transformation matrix.
    corners = [xCorn(:) yCorn(:) zCorn(:) ones(prod(size(xCorn)), 1)];

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


%If we are outside the range of the transformed CT, return empty.
if coord < min(XYZLims{dim}) || coord > max(XYZLims{dim})
    slc = []; sliceXVals = []; sliceYVals = [];
    return;
end

%Mesh the rotated limits to get x,y of new slice.  Use original image res ????wy.
sliceXVals = linspace(XYZLims{imageXDim}(1), XYZLims{imageXDim}(2), XYZRes{imageXDim});
sliceYVals = linspace(XYZLims{imageYDim}(1), XYZLims{imageYDim}(2), XYZRes{imageYDim});

%Perform rotation and return slice, if rotation is required.
if rotation
    
    %Get required mesh values, and set other parameters specific to dim.
    switch dim
        case 1
            %wy
            [xM, yM, zM] = meshgrid(coord, sliceXVals, sliceYVals);
            imgSize      = [1 length(sliceXVals) length(sliceYVals)];
            permuteM     = [3 2 1];
        case 2
            %wy
            [xM, yM, zM] = meshgrid(sliceXVals, coord, sliceYVals);
            imgSize      = [length(sliceXVals) 1 length(sliceYVals)];
            permuteM     = [3 1 2];
            
        case 3
            %wy
            [xM, yM, zM] = meshgrid(sliceXVals, sliceYVals, coord);
            imgSize      = [length(sliceYVals) length(sliceXVals) 1]; %wy
            permuteM     = [1 2 3];
    end

    %Apply transformation to the limits if necessary.
    if isfield(planC{indexS.scan}(scanSet), 'transM')
        mat = [xM(:) yM(:) zM(:) ones(numel(xM), 1)]';
        mat = inv(planC{indexS.scan}(scanSet).transM) * mat;
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

    %Need at least 2 Z slices.
    switch dim
        case 3
            if isequal(minZ, maxZ)                
                maxZ = minZ+1;
                if size(scanArray,3) < maxZ
                    minZ = minZ-1;
                    maxZ = maxZ-1;
                end
            end
            
        case 2
            if isequal(minY, maxY)
                maxY = minY+1;
            end
            
        case 1
            if isequal(minX, maxX)
                maxX = minX+1;
            end
    end

    %Prepare the x,y,z vector inputs for finterp3.
    xVec = [xV(minX)-eps*10^10 xV(2)-xV(1) xV(maxX)+eps*10^10];
    yVec = [yV(maxY)+eps*10^10 yV(2)-yV(1) yV(minY)-eps*10^10];
    zVec = zV(minZ:maxZ);

    %Interpolate to get slice.
    slc = finterp3(xM(:), yM(:), zM(:), scanArray(maxY:minY, minX:maxX, minZ:maxZ), xVec, yVec, zVec,0);

    %Reshape the linear slice to 2D. Permute to get proper orientation.
    slc = reshape(slc, imgSize);
    slc = permute(slc, permuteM);
    slc = squeeze(slc);

else %Rotation is not required, use simple linear interpolation.
    xV = xV + xT;
    yV = yV + yT;
    zV = zV + zT;

    switch dim
        case 1
            slice = interp1(xV, 1:length(xV), coord);
%             slice = finterp1(xV, 1:length(xV), coord);
            deltaX = yT;
            deltaY = zT;
        case 2
            slice = interp1(yV, 1:length(yV), coord);
%             slice = finterp1(yV, 1:length(yV), coord);
            deltaX = xT;
            deltaY = zT;
        case 3
            if length(zV) > 1
                [uniqZv, indUnq] = unique(zV);
                indAll = 1:length(zV);
                slice = interp1(uniqZv, indAll(indUnq), coord);
                %slice = interp1(zV, 1:length(zV), coord);
            else
                slice = 1;
            end
%             slice = finterp1(zV, 1:length(zV), coord);
            deltaX = xT;
            deltaY = yT;
    end
    lowerSlc = floor(slice);
    upperSlc = ceil(slice);
    lowerSlcRatio = (upperSlc - slice);
    upperSlcRatio = 1 - lowerSlcRatio;
    %     getCTSlice(planC{indexS.scan}(scanSet), lowerSlc, dim);
    if isequal(lowerSlc, upperSlc)
        [slc, sliceXVals, sliceYVals, planC] = getCTSlice(planC{indexS.scan}(scanSet), uint16(lowerSlc), dim, planC);
    else
        [upslc, sliceXVals, sliceYVals, planC] = getCTSlice(planC{indexS.scan}(scanSet), uint16(upperSlc), dim, planC);
        [lowslc, sliceXVals, sliceYVals, planC] = getCTSlice(planC{indexS.scan}(scanSet), uint16(lowerSlc), dim, planC);
        upperSlcRatio = slice - lowerSlc;
        slc = double(lowslc)*(lowerSlcRatio) + double(upslc)*(upperSlcRatio);
    end
    sliceXVals = sliceXVals + deltaX;
    sliceYVals = sliceYVals + deltaY;
    slc = squeeze(slc);
end
slc = double(slc);

% if strcmpi(planC{indexS.scan}(scanSet).scanInfo(1).imageType,'PET') & (max(slc(:))< 100)
%     slc = slc .* 1000;
% end




function [bool, xT, yT, zT] = isrotation(transM)
%"isrotation"
%   Returns true if transM includes rotation.  If it doesn't include
%   rotation, bool=0. xT,yT,zT are the translations in x,y,z
%   respectively.

xT = transM(1,4);
yT = transM(2,4);
zT = transM(3,4);

transM(1:3,4) = 0;
bool = ~isequal(transM, eye(4));
