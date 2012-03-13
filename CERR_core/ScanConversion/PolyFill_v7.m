function maskM = PolyFill_v7(pointsM,optS)
%function maskM = PolyFill_v7(pointsM,optS)
%fastPoly_v7: returns a matrix maskM of size [numRows,numCols],
%[numRows,numCols] are passed via optS.
%numRows = imageSizeV(1); numCols = imageSizeV(2);
%where, imageSizeV = optS.ROIImageSize;
%Intention is to only fill a voxel if it's center is inside or 
%on the polygon edges.
%Uses MATLAB built-in function 'inpolygon'.
%
%APA; 06 Oct 05.
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

imageSizeV = optS.ROIImageSize;

xOffset = optS.xCTOffset;
yOffset = optS.yCTOffset;

numRows = imageSizeV(1);
numCols = imageSizeV(2);

xInV = pointsM(:,1);
yInV = pointsM(:,2);

maskM = zeros(numRows,numCols);

%convert to "row and col space", that is, a continuous space where
%s is a coord that runs from 1 to numCols (along x axis)
%t is a coord that runs from 1 to numRows (along -y axis)
numCols=double(numCols); numRows=double(numRows);
sInV = (xInV - xOffset)/optS.ROIxVoxelWidth + (numCols + 1)/2;  %%% APA: becomes (-)ve when drawn out of axis ranges
tInV = (yInV - yOffset)/optS.ROIyVoxelWidth + (numRows + 1)/2;


% USE 'inpolygon' to get the mask
s=[sInV; sInV(1)]; t=[tInV; tInV(1)];
[S,T]=meshgrid(1:numRows,1:numCols);
maskM=inpolygon(S,T,s,t);
maskM=flipud(maskM);

return
