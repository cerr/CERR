function indexV = KonRadCube(indexV, size)
%"KonRadCube"
%   Convert voxels indexed using the CERR method to KonRad.
%
%   CERR uses matlab matrix indexing, (row,col,slice) where the first row is
%   anterior, the first column is to the patient's right, and the first slice
%   is the most superior.
%
%   (I think) KonRad uses (x,y,z) indexing where the first x is to the patient's right,
%   the first y is posterior, and the first z is the most inferior.
%
%JRA 3/11/04
%
%Usage:
%   function indexV = KonRadCube(indexV, size)
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

numRow = size(1);
numCol = size(2);
numSlic = size(3);
[r,c,s] = ind2sub(size, indexV);

%x is the same as columns in CERR.
x = c;
%Y is the same as rows in CERR, but indexed in the reverse.
y = numRow+1 - r;
%Z is the same as slices in CERR, but indexed in the reverse.
z = numSlic+1 - s;

%Convert back to indices.
indexV = sub2ind(size,x,y,z);