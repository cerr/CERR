function h = ref_lconv(f,g,ctype)
%-*- texinfo -*-
%@deftypefn {Function} ref_lconv
%@verbatim
%REF_LCONV  Reference linear convolution
%   Usage:  h=ref_lconv(f,g)
%
%   PCONV(f,g) computes the linear convolution of f and g.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_lconv.html}
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

Lf = length(f);
Lg = length(g);

Lh = Lf+Lg-1;

f = [f; zeros(Lh - Lf, 1)];
g = [g; zeros(Lh - Lg, 1)];

h = zeros(Lf+Lg-1, 1);

switch(lower(ctype))
	case {'default'}
    for ii = 0 : Lh-1
      for jj = 0 : Lh-1
        h(ii+1)=h(ii+1)+f(jj+1)*g(mod(ii-jj,Lh)+1);
      end
    end
  case {'r'}
    for ii=0:Lh-1
      for jj=0:Lh-1
	      h(ii+1)=h(ii+1)+f(jj+1)*conj(g(mod(jj-ii, Lh)+1));
      end;
   	end;
  case {'rr'}
    for ii=0:Lh-1
      for jj=0:Lh-1
	      h(ii+1)=h(ii+1)+conj(f(mod(-jj, Lh)+1))*conj(g(mod(jj-ii,Lh)+1));
      end;
    end;
end
      

