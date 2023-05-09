function f=ref_idft(c)
%-*- texinfo -*-
%@deftypefn {Function} ref_idft
%@verbatim
%REF_IDFT  Reference Inverse Discrete Fourier Transform
%   Usage:  f=ref_dft(c);
%
%   REF_IDFT(f) computes the unitary discrete Fourier transform of the 
%   coefficient c.
%
%   AUTHOR: Jordy van Velthoven
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_idft.html}
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

L = length(c);
f = zeros(L,1);

for l=0:L-1
  for k=0:L-1
    f(l+1) = f(l+1) + c(k+1) * exp(2*pi*i*k*l/L);
  end;
end;

f = f/sqrt(L);

