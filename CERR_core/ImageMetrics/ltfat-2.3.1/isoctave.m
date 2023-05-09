function t=isoctave()
%-*- texinfo -*-
%@deftypefn {Function} isoctave
%@verbatim
%ISOCTAVE  True if the operating environment is octave
%   Usage: t=isoctave();
%
%   ISOCTAVE returns 1 if the operating environment is Octave, otherwise
%   it returns 0 (Matlab)
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/isoctave.html}
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

%   AUTHOR : Peter L. Soendergaard.  
%   TESTING: NA
%   REFERENCE: NA
persistent inout;

if isempty(inout),
  inout = exist('OCTAVE_VERSION','builtin') ~= 0;
end;
t = inout;

