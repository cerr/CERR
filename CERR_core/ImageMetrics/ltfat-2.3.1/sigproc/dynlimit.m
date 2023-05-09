function xo=dynlimit(xi,dynrange,varargin);
%-*- texinfo -*-
%@deftypefn {Function} dynlimit
%@verbatim
%DYNLIMIT  Limit the dynamical range of the input
%   Usage: xo=dynlimit(xi,dynrange);
%
%   DYNLIMIT(xi,dynrange) will threshold the input such that the
%   difference between the maximum and minumum value of xi is exactly
%   dynrange.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/sigproc/dynlimit.html}
%@seealso{thresh, largestr, largestn}
%@end deftypefn

% Copyright (C) 2005-2016 Peter L. Soendergaard <peter@sonderport.dk>.
% This file is part of LTFAT version 2.3.1
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.
  
xmax=max(xi(:));
xo=xi;
xo(xo<xmax-dynrange)=xmax-dynrange;

