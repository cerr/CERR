function L=nsdgtlength(Ls,a);
%-*- texinfo -*-
%@deftypefn {Function} nsdgtlength
%@verbatim
%NSDGTLENGTH  NSDGT length from signal
%   Usage: L=nsdgtlength(Ls,a);
%
%   NSDGTLENGTH(Ls,a) returns the length of an NSDGT with time shifts
%   a, such that it is long enough to expand a
%   signal of length Ls.
%
%   If the returned length is longer than the signal length, the signal
%   will be zero-padded by NSDGT or UNSDGT.
%
%   If instead a set of coefficients are given, call NSDGTLENGTHCOEF.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/nonstatgab/nsdgtlength.html}
%@seealso{nsdgt, nsdgtlengthcoef}
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

if ~isnumeric(Ls)
  error('%s: Ls must be numeric.',upper(mfilename));
end;

if ~isscalar(Ls)
  error('%s: Ls must a scalar.',upper(mfilename));
end;

if ~isnumeric(a)
  error('%s: a must be numeric.',upper(mfilename));
end;

if ~isvector(a) || any(a<0)
  error('%s: "a" must be a vector of non-negative numbers.',upper(mfilename));
end;

L=sum(a);

if Ls>L
    error('%s: The signal must have at most %i samples.',upper(mfilename),L);
end;

