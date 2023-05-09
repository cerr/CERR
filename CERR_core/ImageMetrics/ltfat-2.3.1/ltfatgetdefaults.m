function d=ltfatgetdefaults(fname)
%-*- texinfo -*-
%@deftypefn {Function} ltfatgetdefaults
%@verbatim
%LTFATGETDEFAULTS  Get default parameters of function
%
%   LTFATGETDEFAULTS(fname) returns the default parameters
%   of the function fname as a cell array.
%
%   LTFATGETDEFAULTS('all') returns all the set defaults.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/ltfatgetdefaults.html}
%@seealso{ltfatsetdefaults, ltfatstart}
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

if nargin<1
    error('%s: Too few input arguments',upper(mfilename));
end;

if strcmpi(fname,'all')
  d=ltfatarghelper('all');
else
  d=ltfatarghelper('get',fname);
end;


