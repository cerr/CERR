function rasterSegs = structMargin(rasterSegs1, margin, scanNum, planC)
%"structMargin"
%   Returns a 2D margin of size <margin> cm, around the _edge_ of the
%   structure specified by rasterSegs1.  Example: if the source structure
%   is a filled in circle, the output is a donut with width margin*2.
%   The circle's edge was convolved with a circular mask of radius margin.
%
%   To get the original mask + a margin perform a struct union between the
%   orignal mask and the output of structMargin.
%
%   To get the original mask - a margin perform a struct diff between the
%   original mask and the output of structMargin.
%
%   By JRA 10/1/03
%
%   rasterSegs1    :    rasterSegs of structure to get margin of.
%   margin         :    margin in cm (MUST BE POSITIVE).
%   scanNum        :    scanNumber rasterSegments are associated with.
%   planC          :    CERR planC
%
%   rasterSegs     :    rasterSegs of resulting structure.
%
%Usage:
%   rasterSegs = structMargin(rasterSegs1, margin, scanNum, planC)
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
rasterSegs = [];

%sort input rasterSegments by CTSliceValue
rasterSegs1 = sortrows(rasterSegs1, 6);

%get list of CTSlices to iterate over.
slices1 = unique(rasterSegs1(:,6));

%for margin, only need to worry about slices where structure has segments
slicesToCalculate = slices1;

%for each slice we are calculating on do the margin.
for i=1:length(slicesToCalculate)
    sliceNum = slicesToCalculate(i);
    rasterIndices = find(rasterSegs1(:,6) == sliceNum);
    mask1 = rasterToMask(rasterSegs1(rasterIndices,:), scanNum, planC);    
    marginMask = calculateMargin(mask1, margin, scanNum, planC);
    rasterSegs = [rasterSegs;maskToRaster(marginMask, sliceNum, scanNum, planC)];
end


function result = calculateMargin(data, margin, scanNum, planC)

    [origxSize, origySize] = size(data);

    [xIncVals, yIncVals, junk] = mtoxyz([1 2], [1 2], [1 2], scanNum, planC);
    xInc = abs(xIncVals(2) - xIncVals(1));
    yInc = abs(yIncVals(2) - yIncVals(1));

	%Given pixel widths in cm, create a circular mask of radius <radius>.
	mask = getmask(xInc, yInc, margin);
	[maskXSize, maskYSize] = size(mask);
    
    tmp = zeros(size(data,1)+2*maskXSize, size(data,2)+2*maskYSize);
    tmp(maskXSize+1:size(data,1)+maskXSize, maskYSize+1:size(data,2)+maskYSize) = data;
    data = tmp;    

  	[xSize, ySize] = size(data);
	result = false(xSize*ySize,1);
   
    %method 1
    %edgePoints = edginess(data);
    %method 2, faster and more precise   
    edgePoints = edginess2(data);
    
    edgeIndex = find(edgePoints(:)); %Vectorize for speed
    [xMask, yMask] = find(mask);
    xMask = xMask - (maskXSize+1)/2;
    yMask = yMask - (maskYSize+1)/2;
    
    maskIndex = xMask*xSize + yMask;
    
    for i=1:length(edgeIndex)
        %apply the thingy. Think about removing loop. UPDATE, removing loop
        %does not help. Efficency question: How can we avoid overlap when
        %applying the mask? Much overlap right now.
        finalIndex = edgeIndex(i) + maskIndex;
        result(finalIndex) = true;
    end
    result = reshape(result, xSize, ySize);
    result = result(maskXSize+1:origxSize+maskXSize, maskYSize+1:origySize+maskYSize);
 
    
function mask = getmask(xinterval, yinterval, radius)

    if length(radius) == 2
        radiusX = radius(2);
        radiusY = radius(1);
    else
        radiusX = radius;
        radiusY = radius;
    end
    xRadius = floor(radiusX/xinterval) * xinterval;
    yRadius = floor(radiusY/yinterval) * yinterval;
    
	[X,Y] = meshgrid(-xRadius:xinterval:xRadius, -yRadius:yinterval:yRadius);
	%R = sqrt(X.^2 + Y.^2) + eps;
	%mask = R<radius;
    %mask = X.^2/xRadius^2 + Y.^2/yRadius^2 < 1;
    mask = X.^2/radiusX^2 + Y.^2/radiusY^2 <= 1;
    
function E = edginess(A) 

	%Old non-vectorized formula: 
	%E = sqrt(((A(i,j)-A(i+1,j+1))^(2))*(A(i+1,j)-A(i,j+1))^(2)+(A(i,j)*A(i+1,j+1)-A(i+1,j)*A(i,j+1))^(2)); 
	
	%Here is a vectorized version: 
	
	A1 = circshift(A,[-1,0]); 
	A2 = circshift(A,[0,-1]); 
	A3 = circshift(A,[-1,-1]); 
	
	C1 = (A - A3).^2; 
	C2 = (A1 - A2).^2; 
	C3 = A .* A3; 
	C4 = A1 .* A2; 
	
	E = (C1 .* C2) + (C3 - C4).^2;    %leave off the final square root for speed. 
	
	E = logical(E); 

function E = edginess2(A)
     firstPass = conv2(A, [0 1 0; 1 50 1; 0 1 0], 'same');
     E = (firstPass > 4 & firstPass < 54);  

