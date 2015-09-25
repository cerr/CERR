function normal = calcVertexNormal(vertexIndex,meshS)
%function normal = calcNormal(vertexIndex,meshS)
%
%This function computes the normal at vertex vertexIndex
%
%APA, 01/09/08
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


% indexS = planC{end};

%Get the edges connecting this vertex
edgeIndices = find(meshS.triangles(:) == vertexIndex);
[rows,cols] = ind2sub(size(meshS.triangles),edgeIndices);
sumCrossProd = [0 0 0];
for i=1:size(rows,1)
    rowIndices = meshS.triangles(rows(i,:),:);
    rowIndices(cols(i)) = [];
    v1 = meshS.vertices(vertexIndex,:) - meshS.vertices(rowIndices(1),:);
    v2 = meshS.vertices(vertexIndex,:) - meshS.vertices(rowIndices(2),:);
    c = cross(v2,v1);
    sumCrossProd = sumCrossProd + c;    
end

normal = sumCrossProd/size(rows,1);
normal = normal/sqrt(sum(normal.^2)+eps);
