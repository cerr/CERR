function R=ref_drihaczekdist(f)
%-*- texinfo -*-
%@deftypefn {Function} ref_drihaczekdist
%@verbatim
%REF_DRIHACZEKDIST  Reference discrete Rihaczek distribution
%   Usage:  R=ref_drihaczekdist(f)
%
%   REF_DRIHACZEKDIST(f) computes the discrete Rihaczek distribution of f.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_drihaczekdist.html}
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

% AUTHOR: Jordy van Velthoven

L = length(f);
c = fft(f);


for m = 0:L-1
  for n=0:L-1
    R(m+1, n+1) = (f(n+1).' * conj(c(m+1))) .* exp(-2*pi*i*m*n/L);
   end
end

