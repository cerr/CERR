function ltfatsetdefaults(fname,varargin)
%-*- texinfo -*-
%@deftypefn {Function} ltfatsetdefaults
%@verbatim
%LTFATSETDEFAULTS  Set default parameters of function
%
%   LTFATSETDEFAULTS(fname,...) sets the default parameters to be the
%   parameters specified at the end of the list of input arguments.
%
%   LTFATSETDEFAULTS(fname) clears any default parameters for the function
%   fname.
%
%   LTFATSETDEFAULTS('clearall') clears all defaults from all functions.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/ltfatsetdefaults.html}
%@seealso{ltfatgetdefaults, ltfatstart}
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

if strcmpi(fname,'clearall')
  ltfatarghelper('clearall');
else
  ltfatarghelper('set',fname,varargin);
end;


