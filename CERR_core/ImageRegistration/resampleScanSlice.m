function slc = resampleScanSlice(scanSetF, scanSetM)
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

global planC stateS;
indexS = planC{end}; 

    [xV1, yV1, zV1] = getScanXYZVals(planC{indexS.scan}(scanSetF));
    [xV2, yV2, zV2] = getScanXYZVals(planC{indexS.scan}(scanSetM));

    XYZRes1  = {length(xV1), length(yV1), length(zV1)};

    xLims1 = [min(xV1) max(xV1)];
    yLims1 = [max(yV1) min(yV1)];
    zLims1 = [min(zV1) max(zV1)];

    sliceXVals1 = linspace(xLims1(1), xLims1(2), XYZRes1{1});
    sliceYVals1 = linspace(yLims1(1), yLims1(2), XYZRes1{2});
    sliceZVals1 = linspace(zLims1(1), zLims1(2), XYZRes1{3});

    for i=1:length(sliceZVals1)
        [xM1, yM1, zM1] = meshgrid(sliceXVals1, sliceYVals1, sliceZVals1(i));

        %Apply transformation to the limits if necessary.
        if isfield(planC{indexS.scan}(scanSetM), 'transM')
            mat = [xM1(:) yM1(:) zM1(:) ones(prod(size(xM1)), 1)]';
            mat = inv(planC{indexS.scan}(scanSetM).transM) * mat;
            xM = mat(1,:);
            yM = mat(2,:);
            zM = mat(3,:);
        end

        %Find corners of scan data included in this slice.
        [minX, jnk] = findnearest(xV2, min(xM(:)));
        [jnk, maxX] = findnearest(xV2, max(xM(:)));
        [minY, jnk] = findnearest(yV2, min(yM(:)));
        [jnk, maxY] = findnearest(yV2, max(yM(:)));

        [minZ, jnk] = findnearest(zV2, min(zM(:)));
        [jnk, maxZ] = findnearest(zV2, max(zM(:)));

        %Prepare the x,y,z vector inputs for finterp3.
        xVec = [xV2(1) xV2(2)-xV2(1) xV2(end)];
        yVec = [yV2(1) yV2(2)-yV2(1) yV2(end)];
        zVec = zV2(minZ:maxZ);

        %Interpolate to get slice.
        im = finterp3(xM(:), yM(:), zM(:), planC{indexS.scan}(scanSetM).scanArray(maxY:minY, minX:maxX, minZ:maxZ), xVec, yVec, zVec,0);

        imgSize      = [length(sliceYVals1) length(sliceXVals1) 1];
        im = reshape(im, imgSize);
        im = squeeze(im);
        slc(:,:,i) = im;        
    end
    
end