function [interpV] = nnfinterp3(xInterpV, yInterpV, zInterpV, field3M, xFieldV, yFieldV, zFieldV, OOBV)
%"nnfinterp3"
%   Fast 3D nearest neighbor interpolation.
%
%   xFieldV and yFieldV are 3 element vectors of the form [xStart, deltaX,
%   xEnd] and [yStart, deltaY, yEnd], where start is the coordinate of the
%   first column(x) or row(y) and end is the coord of the last column/row, 
%   with delta being the spacing.  Delta can be negative if start > end.
%
%   zFieldV must be specified as a list of coordinates for each slice in
%   field3M.
%
%   xInterpV, yInterpV, zInterpV are vectors of equal length indicating the
%   x,y,z, coordinates to interpolate from original data field3M.
%
%   Based on code by J.O.Deasy.
%
%JRA 1/13/05
%
%Usage:
%   function [interpV] = nnfinterp3(xInterpV, yInterpV, zInterpV, field3M, xFieldV, yFieldV, zFieldV, outOfBoundsVal)
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

siz = size(field3M);

if ~exist('OOBV')
    OOBV = NaN;
end

xDelta = xFieldV(2);
yDelta = yFieldV(2);

%Check for row/column vector
sizV = size(xInterpV);
xInterpV = xInterpV(:);
yInterpV = yInterpV(:);
zInterpV = zInterpV(:);
xFieldV = xFieldV(:)';
yFieldV = yFieldV(:)';
zFieldV = zFieldV(:)';

cols = (xInterpV-(xFieldV(1)-xDelta))/xDelta;
rows = (yInterpV-(yFieldV(1)-yDelta))/yDelta;

%Get r,c,s indices.
% cols = interp1q(reshape(xFieldV, [], 1), reshape(1:length(xFieldV),[], 1), reshape(xInterpV, [], 1));
% rows = interp1q(reshape(yFieldV, [], 1), reshape(1:length(yFieldV),[], 1), reshape(yInterpV, [], 1));
if length(zFieldV) > 1;
    %tic, slcs = interp1(zFieldV,1:length(zFieldV),zInterpV); toc
    %fast 1-d interpolation. Haing code here aoids overheads in finterp1.m
    %25% faster compared to finterp1.
    indNaN = zInterpV < min(zFieldV) | zInterpV > max(zFieldV);
    zInterpV(indNaN) = zFieldV(1); %assign DUMMY value
    [jnk,binIndex] = histc(zInterpV,zFieldV);
    yV = (1:length(zFieldV))';
    dxV = [diff(zFieldV) 1]'; %DUMMY 1
    zFieldTransposedV = zFieldV';
    slopeV = 1./dxV;
    slopeV(binIndex==length(zFieldV)) = 0;
    slcs = yV(binIndex) + slopeV(binIndex).*(zInterpV-zFieldTransposedV(binIndex));
    slcs(indNaN) = NaN;
else
    slcs = ones(size(cols));
end

cols = round(cols);
rows = round(rows);
slcs = round(slcs);

clear xInterpV yInterpV zInterpV
clear xFieldV yFieldV zFieldV

%Find indices out of bounds.
colNaN = cols >= siz(2) | cols < 1;
rowNaN = rows >= siz(1) | rows < 1;    
% slcNaN = slcs >= siz(3) | slcs < 1;    

% colNaN = isnan(cols);
% rowNaN = isnan(rows);
slcNaN = isnan(slcs);

%Set those to a proxy 1.
rows(rowNaN) = 1;
cols(colNaN) = 1;
slcs(slcNaN) = 1;

%Linear indices of lower bound contributing points.
%INDEXLIST = round(rows) + (round(cols)-1)*siz(1) + (round(slcs)-1)*siz(1)*siz(2);
INDEXLIST = rows + (cols-1)*siz(1) + (slcs-1)*siz(1)*siz(2);

clear rows cols slcs

%Accumulate contribution from each voxel surrounding x,y,z point.
interpV = field3M(INDEXLIST);

%Replace proxy 1s with out of bounds vals.
interpV(rowNaN | colNaN | slcNaN) = OOBV;

interpV = reshape(interpV,sizV);

return;