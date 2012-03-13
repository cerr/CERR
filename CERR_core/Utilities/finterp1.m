function yi = finterp1(x,y,xi,outOfRangeVal)
%"finterp1"
%   Fast 1-D linear interpolation of regularly spaced vector, to regularly
%   spaced vector/point.
%
% This function does the following
% transformation:	t = (xi-x(1))/(x(end)-x(1))
%                   yi = y(1) + t ( y(end) - y(1) )
%
%   x & y must be a monotonically increasing vector/array;
%
% Written DK 09-27-06
%
% Usage:
%       yi = finterp1(x,y,xi,outOfRangeVal);
%
% See also FINTERP2, FINTERP3, FINTERP3NOMESH ,INTERP1, INTERP2, INTERP3
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


if ~exist('outOfRangeVal')
    outOfRangeVal = NaN;
end

n = length(x);
% check if all the parameters passed are of the same class
superiorfloat(x,y,xi);

try
    h = diff(x);
    [ignore,k] = histc(xi,x);
    k(xi<x(1) | ~isfinite(xi)) = 1;
    k(xi>=x(n)) = n-1;
    t = (xi - x(k))./h(k);
catch % if the vector is monotonically decreasing
    t = (xi-x(1))/(x(end)-x(1));
    k = y(1) + t*(y(end) - y(1));
    k = round(k);
    k(xi<x(1) | ~isfinite(xi)) = 1;
    k(xi>=x(n)) = n-1;
end

yi = y(k)+t.*(y(k+1) - y(k));

% APA Check
% x = x(:);
% xi = xi(:);
% y = y(:);
% dxV = [diff(x); 1]; %DUMMY 1
% if all(dxV(1:end-1)<0)
%     x = flipud(x);
%     y = flipud(y);
%     dxV = [diff(x); 1];
% end    
% dyV = [diff(y); 1]; %DUMMY 1
% indNaN = xi < min(x) | xi> max(x);
% xi(indNaN) = x(1); %assign DUMMY value
% [jnk,binIndex] = histc(xi,x);
% slopeV = dyV./dxV;
% slopeV(binIndex==length(x)) = 0;
% yi = y(binIndex) + slopeV(binIndex).*(xi-x(binIndex));
% yi(indNaN) = outOfRangeVal;
% 
% return;
