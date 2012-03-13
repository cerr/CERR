function rasterSegs = maskToRaster(mask, sliceValues, scanNum, planC)
%"maskToRaster"
%   convert a 3D or 2D mask to a set of rasterSegments denoting logical 'true' values.
%
%   By JRA 10/1/03
%
%   mask:       2D or 3D matrix to convert
%   sliceRange: vector of CT slice numbers corresponding to each z element in the
%               mask, if mask is one slice sliceValues is just that slice's
%               num.
%   planC:      planC file used to convert from pixel values to real xyz coordinates
%
%   rasterSegs: list of rasterSegments for mask.
%
%Usage:
%   rasterSegs = maskToRaster(mask, sliceValues, scanNum, planC)
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
[xSize, ySize, zSize] = size(mask);

rasterSegs = [];

% compute voxelThickness if not provided by planC
if ~isfield(planC{indexS.scan}(scanNum).scanInfo(sliceValues(1)),'voxelThickness')
    voxThickV = deduceVoxelThicknesses(scanNum, planC); 
    voxThickV = voxThickV(sliceValues);
else
    voxThickV = [planC{indexS.scan}(scanNum).scanInfo(sliceValues).voxelThickness];
end

for i = 1:zSize
    %Get signals to indicate where 1s and 0s start and end.
    signals = conv2(double(mask(:,:,i)), [1 3 5]);
    signals = signals(:, 2:end-1);
    
    %CHECK THIS CAREFULLY!!!!! An ASSUMPTION is made about the order FIND
    %uses.!!! x, y values swaped after transposing signals!.
    [rasterStartCol, rasterStartRow] = find(signals' == 4); %4 signals a change from 0s to 1s
    [rasterEndCol, rasterEndRow] = find(signals' == 8); %8 signals a change from 1s to 0s              -- append row and col to size to CT
    [singleVoxelRasterCol, singleVoxelRasterRow] = find(signals' == 3);    
    %convert from row values to real xyz coordinates.
    [xStart, yV, zV] = mtoxyz(rasterStartRow, rasterStartCol, sliceValues(i), scanNum, planC);
    [xStop, junk, junk] = mtoxyz(1, rasterEndCol, 1, scanNum, planC);
    if ~isempty(singleVoxelRasterCol)
        [xSingle, ySingle, zSingle] = mtoxyz(singleVoxelRasterRow, singleVoxelRasterCol, 1, scanNum, planC);
        xStart = [xStart;xSingle];
        xStop  = [xStop;xSingle];
        yV     = [yV;ySingle];
        rasterStartRow = [rasterStartRow; singleVoxelRasterRow];
        rasterStartCol = [rasterStartCol; singleVoxelRasterCol];
        rasterEndCol   = [rasterEndCol; singleVoxelRasterCol];
    end
    [xIncVals, junk, junk] = mtoxyz(1, [1 2], sliceValues(i), scanNum, planC);
    xInc = xIncVals(2) - xIncVals(1);
    %voxThick = planC{indexS.scan}(scanNum).scanInfo(sliceValues(i)).voxelThickness;
    voxThick = voxThickV(i);
    numElements = length(yV);
    rasterSeg = [zV*ones(numElements,1), yV, xStart, xStop, xInc*ones(numElements,1), sliceValues(i)*ones(numElements,1), rasterStartRow, rasterStartCol, rasterEndCol, voxThick*ones(numElements,1)];
    if isempty(rasterSeg)
        %Make sure dimensions are right in the null case, for proper appending.
        rasterSeg = zeros(0,10);    
    end
    rasterSegs = [rasterSegs;rasterSeg];
end
