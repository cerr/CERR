function maskM = fastPolyFill(pointsM,optS)
%function maskM = fastPolyFill(pointsM,optS)
%fastPolyFill:  fills in images given polygons defining edges.
%Intention is to only fill a voxel if it's center is in the polygon.
%Faster than previous version by a significant factor (about x10).
%JOD; 17 June 05.
%Fixed bug, 5 July 05.
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

numRows = double(imageSizeV(1));
numCols = double(imageSizeV(2));

xInV = pointsM(:,1);
yInV = pointsM(:,2);

maskM = zeros(numRows,numCols);
%could also be a double.

%preallocate a table of voxel indices
%'next to' refers to voxel centers just to the right of where polygon
%edges cross a line connecting voxel centers.
nextToPtsM = sparse(numRows * 4, numCols * 4); %hard to imagine bigger (sparse is faster than full)
numNextToPtsV = zeros(numRows,1);

%convert to "row and col space", that is, a continuous space where
%s is a coord that runs from 1 to numCols (along x axis)
%t is a coord that runs from 1 to numRows (along -y axis)
sInV = (xInV - xOffset)/optS.ROIxVoxelWidth + (numCols + 1)/2;
tInV = (yInV - yOffset)/optS.ROIyVoxelWidth + (numRows + 1)/2;

% % APA: snap points to integer-grid using nearest neighbor interpolation and
% % delete duplicates
% [S,T] = meshgrid(1:numCols+1,1:numRows+1);
% indSnap = interp2(S,T,reshape(1:(numCols+1)*(numRows+1),numRows+1,numCols+1),sInV,tInV,'*nearest');
% STpts = [S(ind2sub([numCols+1 numRows+1],indSnap)) T(ind2sub([numCols+1 numRows+1],indSnap))];
% goodPtsV = [1;any(diff(STpts),2)];
% sInV = STpts(find(goodPtsV),1);
% tInV = STpts(find(goodPtsV),2);

%For each polygonal element, compute and add one to 'row starters,' centers of
%voxels (assumed at image coords) whose rows cross the polygonal elements
%and are the first element to the right of that polygonal element's row crossing.
%
%Use the parameterization col = n * deltaRow + c + rowURPt    (URPt = upper
%right point).
%
%Algorithm:
%1.  Determine n
%2.  Determine c
%3.  Determine vector of row crossings
%4.  Determine vector of column crossings
%5.  Add one to row starters.

%Loop over polygonal elements
%For polygonal elements:

shift_sV = [sInV(end); sInV(1:end-1)];
shift_tV = [tInV(end); tInV(1:end-1)];

sM = [sInV(:), shift_sV];
tM = [tInV(:), shift_tV];

%Loop over polygonal edges, put ones where voxel centers are inside
%polygon.
for i = 1 : length(sInV)
    
    if tM(i,1) ~= tM(i,2)   %skip horizontal lines
        
        tMax = max([tM(i,1),tM(i,2)]);
        tMin = min([tM(i,1),tM(i,2)]);
        
        %determine n (line parameterization: s = n * t + c )
        n = (sM(i,1) - sM(i,2))/(tM(i,1) - tM(i,2));
        %determine c, could vectorize these two
        c = sM(i,1) - n * tM(i,1);
        
        %get delta_tV
        tPtsV = ceil(tMin) : floor(tMax);
%         tPtsV = tMin+1 : tMax; % APA
        delta_tV = tPtsV - tMax;
        sPtsV = n * delta_tV + c + n * tMax; %these are s values at edge 'crossings'
        
        %derive s values 'next to the right' of the crossings
        sVoxelsV = ceil(sPtsV);
        
        %catalogue
        for j = 1: length(sVoxelsV)            
            num = numNextToPtsV(tPtsV(j));
            numNextToPtsV(tPtsV(j)) = num + 1;
            nextToPtsM(tPtsV(j),num+1) = sVoxelsV(j);         
        end
        
    end
    
end

%This should be faster than the oft-used cumsum trick:
for i = 1 : numRows
    num = numNextToPtsV(i);
    if num ~=0
        %get 'em
        nextToPtsV = nextToPtsM(i,1:num);
        %sort 'em
        sortPtsV = sort(full(nextToPtsV));
        %fill image
        for j = 1 : length(sortPtsV)/2
            indV = sortPtsV(2*j-1) : sortPtsV(2*j) - 1;
            maskM(i * ones(1,length(indV)),indV) = 1;
        end
    end
end

%lastly, correct an oversight in writing the code: rows need to be flipped:
maskM = flipud(maskM);  %fast operation.


