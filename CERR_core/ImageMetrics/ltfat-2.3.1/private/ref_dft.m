function c=ref_dft(f)
%-*- texinfo -*-
%@deftypefn {Function} ref_dft
%@verbatim
%REF_DFT  Reference Discrete Fourier Transform
%   Usage:  c=ref_dft(f);
%
%   REF_DFT(f) computes the unitary discrete Fourier transform of f.
%
%   AUTHOR: Jordy van Velthoven
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_dft.html}
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

L=size(f,1);
W=size(f,2);
c= zeros(L,W);

for w=1:W
for k=0:L-1
  for l=0:L-1
    c(k+1,w) = c(k+1,w) + f(l+1,w) * exp(-2*pi*i*k*l/L);
  end;
end;
end

c = c./sqrt(L);



