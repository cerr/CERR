function zi = finterp2(x,y,z,xi,yi,uniformFlag,outOfRangeVal);
%"finterp2"
%   Fast 2-D interpolation of regularly spaced matrices, to regularly
%   spaced matrices.  NaNs are not properly handled right now.
%
%   x,y is a VECTOR not a meshgrid of x/yValues of columns/rows.
%   z is the 2D data array
%   xi, yi are the new x,y vectors of the columns/rows wanted.
%
%   If uniformFlag is 1, xi, yi are vectors defining a grid.
%
%JRA 12/8/04
%
%Usage:
%   function zi = finterp2(x,y,z,xi,yi,uniformFlag,outOfRangeVal);
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

if ~exist('outOfRangeVal','var')
    outOfRangeVal = NaN;
end   

if uniformFlag == 1;
	cols = interp1(x(1:end),1:length(x), xi);
	rows = interp1(y(1:end),1:length(y), yi);
	
	colFloor = floor(cols);
%     colFloor = clip(colFloor, 1, length(x)-1, 'delete'); %BLAH
    colNaNIndV = isnan(colFloor) | colFloor < 1 | colFloor >= length(x);
    colFloor(colNaNIndV) = []; %TEMP.
    cols(colNaNIndV) = [];
	colMod   = repmat(mod(cols, 1), [length(y) 1]);
	
	% APA: results in an error using * due to single precision
    colValues = z(:,colFloor).*(1-colMod) + z(:,colFloor+1).*(colMod);
	
	rowFloor = floor(rows);
%     rowFloor = clip(rowFloor, 1, length(y), 'limits'); %BLAH    
    rowNaNIndV = isnan(rowFloor) | rowFloor < 1 | rowFloor >= length(y);   
    rowFloor(rowNaNIndV) = [];
    rows(rowNaNIndV) = [];
	rowMod = repmat(mod(rows, 1)', [1 length(colFloor)]);
	rowModMinusOne = 1-rowMod;
    
    part1 = colValues(rowFloor,:) .* (rowModMinusOne);
    part2 = colValues(rowFloor+1,:) .* (rowMod);
    
    zi = repmat(outOfRangeVal, [length(yi) length(xi)]);
    zi(logical(~rowNaNIndV), logical(~colNaNIndV)) = part1 + part2;
else
    
    siz = size(z);

	xDelta = x(2) - x(1);
	yDelta = y(2) - y(1);

    cols = (xi-(x(1)-xDelta))/xDelta;
    rows = (yi-(y(1)-yDelta))/yDelta;
    colNaN = cols >= siz(2) | cols < 1;
    rowNaN = rows >= siz(1) | rows < 1;    
    
    rows(rowNaN) = 1;
    cols(colNaN) = 1;
    
	colFloor = floor(cols);
    colMod   = cols - colFloor;
    oneMinusColMod = (1-colMod);
    
	rowFloor = floor(rows);
    rowMod = rows - rowFloor;
    oneMinusRowMod = (1-rowMod);    
    
    INDEXLIST = rowFloor + (colFloor-1)*siz(1);
    v1 = z(INDEXLIST) .* oneMinusRowMod .* oneMinusColMod;
    v2 = z(INDEXLIST+1) .* rowMod .* oneMinusColMod;
    v3 = z(INDEXLIST+siz(1)) .* oneMinusRowMod .* colMod; 
    v4 = z(INDEXLIST+(siz(1)+1)) .* rowMod .* colMod;
    
    zi = v1+v2+v3+v4;
    
    zi(rowNaN | colNaN) = NaN;
    
end