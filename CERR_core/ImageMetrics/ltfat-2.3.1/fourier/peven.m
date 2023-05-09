function f=peven(f,dim)
%-*- texinfo -*-
%@deftypefn {Function} peven
%@verbatim
%PEVEN   Even part of periodic function
%   Usage:  fe=peven(f);
%           fe=peven(f,dim);
%
%   PEVEN(f) returns the even part of the periodic sequence f.
%
%   PEVEN(f,dim) does the same along dimension dim.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/fourier/peven.html}
%@seealso{podd, dft, involute, pconv}
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
  
if nargin==1
  f=(f+involute(f))/2;
else
  f=(f+involute(f,dim))/2;
end;


