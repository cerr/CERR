function outV = matInterp3(rowV, colV, sliceV, m3D)
%function outV = matInterp3(rowV, colV, sliceV, m3D)
%Rapid 3D linear interpolation using just row, column, slice-based coords.
%JOD, 17 Nov 03.
%Latest Modification:
%JC, 25 Jun 06: sum outV step by step, to get rid of the 'out of memory' error.
%APA, 28 Nov 06: set dose at out of range indices to zero.
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


sV = size(m3D);

%out of range indices
indOutV = rowV>sV(1) | colV>sV(2) | sliceV>sV(3);
%set those to proxy
rowV(indOutV)   = 1;
colV(indOutV)   = 1;
sliceV(indOutV) = 1;

rUpV   = ceil(rowV);
cUpV   = ceil(colV);
sUpV   = ceil(sliceV);

rDownV = floor(rowV);
cDownV = floor(colV);
sDownV = floor(sliceV);

%Get the interpolation weights
rDeltaV   = (rowV - rDownV);
cDeltaV   = (colV - cDownV);
sDeltaV   = (sliceV - sDownV);

clear rowV colV sliceV

v1 = rUpV + sV(1) * (cUpV - 1) + sV(1) * sV(2) * (sUpV - 1);
outV = m3D(v1) .* rDeltaV .* cDeltaV .* sDeltaV;
clear v1
v2 = rDownV + sV(1) * (cUpV - 1) + sV(1) * sV(2) * (sUpV - 1);
outV = outV + m3D(v2) .* (1-rDeltaV) .* cDeltaV .* sDeltaV;
clear v2

v3 = rUpV + sV(1) * (cDownV - 1) + sV(1) * sV(2) * (sUpV - 1);
outV = outV + m3D(v3) .* rDeltaV .* (1-cDeltaV) .* sDeltaV;
clear v3
v4 = rUpV + sV(1) * (cUpV - 1) + sV(1) * sV(2) * (sDownV - 1);
outV = outV + m3D(v4) .* rDeltaV .* cDeltaV .* (1-sDeltaV);
clear v4

v5 = rDownV + sV(1) * (cDownV - 1) + sV(1) * sV(2) * (sUpV - 1);
outV = outV + m3D(v5) .* (1-rDeltaV) .* (1-cDeltaV) .* sDeltaV;
clear v5
v6 = rDownV + sV(1) * (cUpV - 1) + sV(1) * sV(2) * (sDownV - 1);
outV = outV +  m3D(v6) .* (1-rDeltaV) .* cDeltaV .* (1-sDeltaV);
clear v6

v7 = rUpV + sV(1) * (cDownV - 1) + sV(1) * sV(2) * (sDownV - 1);
outV = outV + m3D(v7) .* rDeltaV .* (1-cDeltaV) .* (1-sDeltaV);
clear v7
v8 = rDownV + sV(1) * (cDownV - 1) + sV(1) * sV(2) * (sDownV - 1);
outV = outV + m3D(v8) .* (1-rDeltaV) .* (1-cDeltaV) .* (1-sDeltaV);
clear v8

%Set out value at out of range indices to 0
outV(indOutV) = 0;
