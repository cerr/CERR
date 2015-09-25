function [interpV] = finterp3(xInterpV, yInterpV, zInterpV, field3M, xFieldV, yFieldV, zFieldV, OOBV)
%"finterp3"
%   Fast 3D linear interpolation of the data field3M defined at
%   xFieldV,yFieldV,zFieldV, to the points listed in x/y/zInterpV.
%
%   xFieldV and yFieldV are 3 element vectors of the form [start, delta, end],
%   where start is the coordinate of the first column(x) or row(y) and end 
%   is the coord of the last column/row, with delta being the spacing.  Delta 
%   can be negative if start > end.
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
%   function [interpV] = finterp3(xInterpV, yInterpV, zInterpV, field3M, xFieldV, yFieldV, zFieldV, outOfBoundsVal)
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

%Get r,c,s indices.
cols = (xInterpV-(xFieldV(1)-xDelta))/xDelta;
rows = (yInterpV-(yFieldV(1)-yDelta))/yDelta;
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
    slcs = ones(size(cols));    %This effectively negates Z.  All values are in plane.  Bad idea?
end

%Find indices out of bounds.
colNaN = cols >= siz(2) | cols < 1;
colLast = (cols-siz(2)).^2 < 1e-3;
yInterpColLastV = yInterpV(colLast);
zInterpColLastV = zInterpV(colLast);

rowNaN = rows >= siz(1) | rows < 1;    
rowLast = (rows-siz(1)).^2 < 1e-3;
xInterpRowLastV = xInterpV(rowLast);
zInterpRowLastV = zInterpV(rowLast);

slcNaN = isnan(slcs) | slcs < 1 | slcs >= siz(3);
slcLast = (slcs-siz(3)).^2 < 1e-3;
xInterpLastV = xInterpV(slcLast);
yInterpLastV = yInterpV(slcLast);

clear xInterpV yInterpV zInterpV
%clear xFieldV yFieldV zFieldV

%Set those to a proxy 1.
rows(rowNaN) = 1;
cols(colNaN) = 1;
slcs(slcNaN) = 1;

colFloor = floor(cols);
colMod   = cols - colFloor;
oneMinusColMod = (1-colMod);

rowFloor = floor(rows);
rowMod = rows - rowFloor;
oneMinusRowMod = (1-rowMod);    

slcFloor = floor(slcs);
slcMod = slcs - slcFloor;
oneMinusSlcMod = (1-slcMod);    

clear rows cols slcs

%Linear indices of lower bound contributing points.
INDEXLIST = rowFloor + (colFloor-1)*siz(1) + (slcFloor-1)*siz(1)*siz(2);

clear rowFloor colFloor slcFloor

%Linear offsets when moving in 3D matrix.
oneRow = 1;
oneCol = siz(1);
oneSlc = siz(1)*siz(2);

%Accumulate contribution from each voxel surrounding x,y,z point.
interpV = double(field3M(INDEXLIST)) .* oneMinusRowMod .* oneMinusColMod .* oneMinusSlcMod;
interpV = interpV + double(field3M(INDEXLIST+(oneRow))) .* rowMod .* oneMinusColMod .* oneMinusSlcMod;
interpV = interpV + double(field3M(INDEXLIST+(oneCol))) .* oneMinusRowMod .* colMod .* oneMinusSlcMod;
interpV = interpV + double(field3M(INDEXLIST+(oneCol+oneRow))) .* rowMod .* colMod .* oneMinusSlcMod;
interpV = interpV + double(field3M(INDEXLIST+(oneSlc))) .* oneMinusRowMod .* oneMinusColMod .* slcMod;
interpV = interpV + double(field3M(INDEXLIST+(oneSlc+oneRow))) .* rowMod .* oneMinusColMod .* slcMod;
interpV = interpV + double(field3M(INDEXLIST+(oneSlc+oneCol))) .* oneMinusRowMod .* colMod .* slcMod;
interpV = interpV + double(field3M(INDEXLIST+(oneSlc+oneCol+oneRow))) .* rowMod .* colMod .* slcMod;

%Replace proxy 1s with out of bounds vals.
interpV(rowNaN | colNaN | slcNaN) = OOBV;

%2D interpolate last slice
if any(slcLast)
    if strcmpi(computer,'PCWIN') || strcmpi(computer,'GLNXA64')  || strcmpi(computer,'PCWIN64') || strcmpi(computer,'MACI64') || strcmpi(computer,'MAC') || strcmpi(computer,'MACI')
        interpV(slcLast) = interp2(xFieldV(1):xFieldV(2):xFieldV(3), yFieldV(1):yFieldV(2):yFieldV(3), double(field3M(:,:,end)), xInterpLastV, yInterpLastV,'linear',OOBV);
    else
        interpV(slcLast) = interp2(xFieldV(1):xFieldV(2):xFieldV(3), yFieldV(1):yFieldV(2):yFieldV(3), double(field3M(:,:,end)), xInterpLastV, yInterpLastV,'linear',OOBV);
    end
end

if any(colLast)
    if length(zFieldV) > 1
        if strcmpi(computer,'PCWIN') || strcmpi(computer,'GLNXA64')  || strcmpi(computer,'PCWIN64') || strcmpi(computer,'MACI64') || strcmpi(computer,'MAC') || strcmpi(computer,'MACI')
            interpV(colLast) = interp2(yFieldV(1):yFieldV(2):yFieldV(3), zFieldV, double(squeeze(field3M(:,end,:))'), yInterpColLastV, zInterpColLastV,'linear',OOBV);
        else
            interpV(colLast) = interp2(yFieldV(1):yFieldV(2):yFieldV(3), zFieldV, double(squeeze(field3M(:,end,:))), yInterpColLastV, zInterpColLastV,'linear',OOBV);
        end
    end
end

if any(rowLast)
    if length(zFieldV) > 1
        if strcmpi(computer,'PCWIN') || strcmpi(computer,'GLNXA64') || strcmpi(computer,'PCWIN64') || strcmpi(computer,'MACI64') || strcmpi(computer,'MAC') || strcmpi(computer,'MACI')
            interpV(rowLast) = interp2(xFieldV(1):xFieldV(2):xFieldV(3), zFieldV, double(squeeze(field3M(end,:,:))'), xInterpRowLastV, zInterpRowLastV,'linear',OOBV);
        else
            interpV(rowLast) = interp2(xFieldV(1):xFieldV(2):xFieldV(3), zFieldV, double(squeeze(field3M(end,:,:))), xInterpRowLastV, zInterpRowLastV,'linear',OOBV);
        end
    end
end

interpV = reshape(interpV,sizV);

return;