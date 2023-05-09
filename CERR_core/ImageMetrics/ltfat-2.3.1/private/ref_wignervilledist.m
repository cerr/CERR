function W=ref_wignervilledist(f,g)
%-*- texinfo -*-
%@deftypefn {Function} ref_wignervilledist
%@verbatim
%REF_WIGNERVILLEDIST Reference wigner-Ville distribution
%   Usage:  W=ref_wignervilledist(f)
%
%   REF_WIGNERVILLEDIST(f,g) computes the Wigner-Ville distribution of f and g.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_wignervilledist.html}
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

if ~all(length(f)==length(g))
  error('%s: f and g must have the same length.', upper(mfilename));
end;

L = length(f);
H = floor(L/2);
R = zeros(L,L);
W = zeros(L,L);

% Compute the analytic representation of f
if (nargin == 1)
  if isreal(f)
   z = fft(f);
   z(2:L-H) = 2*z(2:L-H);
   z(H+2:L) = 0;
   z1 = ifft(z);
   z2 = z1;
  else
   z1 = f;
   z2 = z1;
  end
elseif (nargin == 2)
  if isreal(f) || isreal(g)
   z1 = fft(f);
   z1(2:L-H) = 2*z1(2:L-H);
   z1(H+2:L) = 0;
   z1 = ifft(z1);
   z2 = fft(g);
   z2(2:L-H) = 2*z2(2:L-H);
   z2(H+2:L) = 0;
   z2 = ifft(z2);
  else
    z1 = f;
    z2 = g;
  end
end

% Compute instantaneous autocorrelation matrix R
for l = 0 : L-1;
  for m = -min([L-l, l, round(L/2)-1]) : min([L-l, l, round(L/2)-1]);
    R(mod(L+m,L)+1, l+1) =  z1(mod(l+m, L)+1).*conj(z2(mod(l-m, L)+1));
  end
end

% Compute the Wigner-Ville distribution
for hh=0:L-1
  for ii=0:L-1
    for jj = 0:L-1
      W(hh+1, ii+1) = W(hh+1, ii+1) + R(jj+1, ii+1) .* exp(-2*pi*i*hh*jj/L);
    end
  end
end

