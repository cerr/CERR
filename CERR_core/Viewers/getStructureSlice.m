function [slcC, sliceXVals, sliceYVals] = getStructureSlice(scanSet, dim, coord, transM, planC)
%"getStructureSlice"
%   Return a slice of scanSet's uniformized data, in dimension
%   dim (x,y,z = 1,2,3) at coordinate coord.  If the scanSet has
%   a transformation matrix, the slice returned is from the transformed
%   uniformized data.
%
%   sliceXVals and sliceYVals are the coordinates of the cols/rows of the
%   slice.
%
%JRA 12/17/04
%
%Usage:
%   function [slc, sliceXVals, sliceYVals] = getStructureSlice(structNum, dim, coord, transM);
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

if ~exist('planC','var')
global planC
end

indexS = planC{end};

%Check the scan for transM, and if it has any rotation component.
if isfield(planC{indexS.scan}(scanSet), 'transM') && ~isempty(planC{indexS.scan}(scanSet).transM) && ~exist('transM','var')
    transM = planC{indexS.scan}(scanSet).transM;
    [rotation, xT, yT, zT] = isrotation(transM);
elseif (~isfield(planC{indexS.scan}(scanSet),'transM') || isempty(planC{indexS.scan}(scanSet).transM)) && ~exist('transM','var')
    transM = eye(4);    
    rotation = 0; xT = 0; yT = 0; zT = 0;
else
    [rotation, xT, yT, zT] = isrotation(transM);
end

%Get the coordinates of the original scan.
uniformScanInfo = planC{indexS.scan}(scanSet).uniformScanInfo;
if isempty(uniformScanInfo)
     planC = setUniformizedData(planC);
end

[xV, yV, zV] = getUniformScanXYZVals(planC{indexS.scan}(scanSet));

%Figure out which spatial dimension is in the slice's X and Y direction.
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

if rotation
    %Get the corners of the original scan.
    [xCorn, yCorn, zCorn] = meshgrid(xLims, yLims, zLims);

    %Add ones to the corners so we can apply a transformation matrix.
    corners = [xCorn(:) yCorn(:) zCorn(:) ones(numel(xCorn), 1)];

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
XYZRes  = {length(xV), length(yV), length(zV)};

%If we are outside the range of the transformed CT, return empty.
if coord < min(XYZLims{dim}) | coord > max(XYZLims{dim})
    slcC = []; sliceXVals = []; sliceYVals = [];
    return;
end

%Mesh the rotated limits to get x,y of new slice.  Use original image res.
imageXVals = linspace(XYZLims{imageXDim}(1), XYZLims{imageXDim}(2), XYZRes{imageXDim});
imageYVals = linspace(XYZLims{imageYDim}(1), XYZLims{imageYDim}(2), XYZRes{imageYDim});

%Perform rotation and return slice, if rotation is required.
if rotation
    %Get required mesh values, and set other parameters specific to dim.
    switch dim
        case 1
            [xM, yM, zM] = meshgrid(coord, imageXVals, imageYVals);
            imgSize      = [1 length(imageXVals) length(imageYVals)];
            permuteM     = [3 2 1];
        case 2
            [xM, yM, zM] = meshgrid(imageXVals, coord, imageYVals);
            imgSize      = [length(imageXVals) 1 length(imageYVals)];
            permuteM     = [3 1 2];
        case 3
            [xM, yM, zM] = meshgrid(imageXVals, imageYVals, coord);
            imgSize      = [length(imageYVals) length(imageXVals) 1];
            permuteM     = [1 2 3];
    end

    %Apply transformation to the limits if necessary.
    if ~isequal(transM,eye(4))
        mat = [xM(:) yM(:) zM(:) ones(numel(xM), 1)]';
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

    %Prepare the x,y,z vector inputs for nnfinterp3.
    xVec = [xV(minX) xV(2)-xV(1) xV(maxX)];
    yVec = [yV(maxY) yV(2)-yV(1) yV(minY)];
    zVec = zV(minZ:maxZ);
    
    saNum = getScanAssociatedStructureArray(scanSet,[],planC);
    
    %Get bits for structures less than or equal to 52
    indicesM = planC{indexS.structureArray}(saNum).indicesArray;
    bitsM = planC{indexS.structureArray}(saNum).bitsArray;

    keepers = indicesM;

    zMinTest = (keepers(:,3) >= minZ);
    keepers  = keepers(zMinTest,:);
    zMaxTest = (keepers(:,3) <= maxZ);
    keepers  = keepers(zMaxTest,:);

    xMinTest = (keepers(:,2) >= minX);
    keepers  = indicesM(xMinTest,:);
    xMaxTest = (keepers(:,2) <= maxX);
    keepers  = keepers(xMaxTest,:);

    yMinTest = (keepers(:,1) >= maxY);
    keepers  = keepers(yMinTest,:);
    yMaxTest = (keepers(:,1) <= minY);

    indV = 1:size(indicesM,1);

    a = indV(zMinTest);
    clear zMinTest; clear indV;
    b = a(zMaxTest);
    clear a; clear zMaxTest;
    c = b(xMinTest);
    clear b; clear xMinTest;
    d = c(xMaxTest);
    clear c; clear xMaxTest;
    e = d(yMinTest);
    clear d; clear yMinTest;
    f = e(yMaxTest);
    clear e; clear yMaxTest;
    inSliceMatrix = f;
    clear f;

    %     inSliceMatrix = find(includeV);

    switch class(bitsM)
        case 'uint8'
            sliceMatrix = repmat(uint8(0), [minY-maxY+1, maxX-minX+1, maxZ-minZ+1]);
        case 'uint16'
            sliceMatrix = repmat(uint16(0), [minY-maxY+1, maxX-minX+1, maxZ-minZ+1]);
        case 'uint32'
            sliceMatrix = repmat(uint32(0), [minY-maxY+1, maxX-minX+1, maxZ-minZ+1]);
        case 'double'
            sliceMatrix = repmat(double(0), [minY-maxY+1, maxX-minX+1, maxZ-minZ+1]);
    end
    %     sliceMatrix = zeros(minY-maxY+1, maxX-minX+1, maxZ-minZ+1);

    coord3D = double(indicesM(inSliceMatrix,:));
    offsets = repmat([-maxY+1, -minX, -minZ], [length(inSliceMatrix), 1]);
    coord3D = coord3D+offsets;

    indV = coord3D * [1 size(sliceMatrix,1) size(sliceMatrix,1)*size(sliceMatrix,2)]';

    sliceMatrix(indV) = bitsM(inSliceMatrix);

    %Perform fast nearest neighbor interpolation.
    slc = nnfinterp3(xM(:), yM(:), zM(:), sliceMatrix, xVec, yVec, zVec, 0);

    %Reshape the linear slice to 2D. Permute to get proper orientation.
    slc = reshape(slc, imgSize);
    slc = permute(slc, permuteM);
    
    slcC{1} = slc;
    
    %Get bits for structures beyond 52

    indicesC = planC{indexS.structureArrayMore}(saNum).indicesArray;
    bitsC = planC{indexS.structureArrayMore}(saNum).bitsArray;

    for cellNum = 1:length(bitsC)

        indicesM = indicesC{cellNum};
        bitsM = bitsC{cellNum};
        
        inSliceMatrix = find((indicesM(:,3) >= minZ) & (indicesM(:,3) <= maxZ) & (indicesM(:,2) >= minX) & (indicesM(:,2) <= maxX) & (indicesM(:,1) >= maxY) & (indicesM(:,1) <= minY));

        sliceMatrix = repmat(uint8(0), [minY-maxY+1, maxX-minX+1, maxZ-minZ+1]);
        
        coord3D = double(indicesM(inSliceMatrix,:));
        offsets = repmat([-maxY+1, -minX, -minZ], [length(inSliceMatrix), 1]);
        coord3D = coord3D+offsets;

        indV = coord3D * [1 size(sliceMatrix,1) size(sliceMatrix,1)*size(sliceMatrix,2)]';

        sliceMatrix(indV) = bitsM(inSliceMatrix);

        %Perform fast nearest neighbor interpolation.
        slc = nnfinterp3(xM(:), yM(:), zM(:), sliceMatrix, xVec, yVec, zVec, 0);

        %Reshape the linear slice to 2D. Permute to get proper orientation.
        slc = reshape(slc, imgSize);
        slc = permute(slc, permuteM);
        slcC{cellNum+1} = slc;
    end
    sliceXVals = imageXVals;
    sliceYVals = imageYVals;


else %Rotation is not required, use simple linear interpolation.

    xV = xV + xT;
    yV = yV + yT;
    zV = zV + zT;
    
    saNum = getScanAssociatedStructureArray(scanSet,[],planC);
    
    %Get bits for structures less than or equal to 52
    
    indicesM = planC{indexS.structureArray}(saNum).indicesArray;
    bitsM = planC{indexS.structureArray}(saNum).bitsArray;

    if isempty(indicesM)
        slcC = [];
        sliceXVals = [];
        sliceYVals = [];
        return;
    end

    switch dim
        case 1
            slice = interp1(xV, 1:length(xV), coord);
            uniDim = 2; otherDims = [1 3];
            sliceMatrix = zeros(length(yV), length(zV));
            sliceXVals = yV; sliceYVals = zV;
        case 2
            slice = interp1(yV, 1:length(yV), coord);
            uniDim = 1; otherDims = [2 3];
            sliceMatrix = zeros(length(xV), length(zV));
            sliceXVals = xV; sliceYVals = zV;
        case 3
            if length(zV) > 1
                slice = interp1(zV, 1:length(zV), coord);
            else
                slice = 1;
            end
            uniDim = 3; otherDims = [1 2];
            sliceMatrix = zeros(length(yV), length(xV));
            sliceXVals = xV; sliceYVals = yV;
    end
    slice = round(slice);

    includeV = indicesM(:,uniDim) == uint16(slice);
       
    coord2D = uint32(indicesM(includeV,:));
    
    indV = coord2D(:,otherDims(1)) + (coord2D(:,otherDims(2))-1) * ...
        uint32(size(sliceMatrix,1));
    
    sliceMatrix(indV) = bitsM(includeV);

    slcC{1} = sliceMatrix';
    
       
    %Get bits for structures beyond 52

    indicesC = planC{indexS.structureArrayMore}(saNum).indicesArray;
    bitsC = planC{indexS.structureArrayMore}(saNum).bitsArray;
    if isempty(indicesC)
        slcC{2} = [];
        return;
    end
    for cellNum = 1:length(bitsC)

        indicesM = indicesC{cellNum};
        bitsM = bitsC{cellNum};

        if isempty(indicesM)
            slcC{cellNum+1} = [];
            %sliceXVals = [];
            %sliceYVals = [];
            continue
        end

        switch dim
            case 1
                slice = interp1(xV, 1:length(xV), coord);
                uniDim = 2; otherDims = [1 3];
                sliceMatrix = zeros(length(yV), length(zV));
                sliceXVals = yV; sliceYVals = zV;
            case 2
                slice = interp1(yV, 1:length(yV), coord);
                uniDim = 1; otherDims = [2 3];
                sliceMatrix = zeros(length(xV), length(zV));
                sliceXVals = xV; sliceYVals = zV;
            case 3
                slice = interp1(zV, 1:length(zV), coord);
                uniDim = 3; otherDims = [1 2];
                sliceMatrix = zeros(length(xV), length(yV));
                sliceXVals = xV; sliceYVals = yV;
        end
        slice = round(slice);

        includeV = indicesM(:,uniDim) == uint16(slice);

        coord2D = uint32(indicesM(includeV,otherDims));

        coord2D(:,2) = coord2D(:,2)-1;

        indV = coord2D(:,1) + coord2D(:,2) * uint32(size(sliceMatrix,1));

        sliceMatrix(indV) = bitsM(includeV);

        slc = sliceMatrix';

        slcC{cellNum+1} = slc;

    end

end


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