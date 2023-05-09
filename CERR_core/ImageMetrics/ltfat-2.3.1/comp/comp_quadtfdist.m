function p = comp_quadtfdist(f, q);;
%-*- texinfo -*-
%@deftypefn {Function} comp_quadtfdist
%@verbatim
% Comp_QUADTFDIST Compute quadratic time-frequency distribution
%   Usage p = comp_quadtfdist(f, q);;
%
%   Input parameters:
%         f      : Input vector
%	  q	 : Kernel
%
%   Output parameters:
%         p      : Quadratic time-frequency distribution
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_quadtfdist.html}
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

if isreal(f)
 z = comp_fftanalytic(f);
else
 z = f;
end;

R = comp_instcorrmat(z,z);

c = ifft2(fft2(R).*fft2(q));

p = fft(c);



