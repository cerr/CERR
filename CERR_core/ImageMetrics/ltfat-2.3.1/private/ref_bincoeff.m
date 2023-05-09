function out=ref_bincoeff(u,v)
%-*- texinfo -*-
%@deftypefn {Function} ref_bincoeff
%@verbatim
%REF_BINCOEFF  Binomial coefficients, possibly rational
%
%  Compted by lambda functions.
%
%  See formula 1.2 in Unsers paper: "Fractional splines and wavelets"
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_bincoeff.html}
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

out=gamma(u+1)./(gamma(v+1).*gamma(u-v+1));





