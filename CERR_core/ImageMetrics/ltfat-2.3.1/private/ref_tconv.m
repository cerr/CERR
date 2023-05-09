function h=ref_tconv(f,g,a)
%-*- texinfo -*-
%@deftypefn {Function} ref_tconv
%@verbatim
%REF_PCONV  Reference TCONV
%   Usage:  h=ref_tconv(f,g,a)
%
%   TCONV(f,g,a) computes the twisted convolution of f and g.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_tconv.html}
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

% AUTHOR: Peter L. Soendergaard

M=size(f,1);
N=size(f,2);

h=zeros(M,N);

theta=a/M;

for m=0:M-1
  for n=0:N-1
    for l=0:N-1
      for k=0:M-1
	h(m+1,n+1)=h(m+1,n+1)+f(k+1,l+1)*g(mod(m-k,M)+1,mod(n-l,N)+1)*...
	    exp(2*pi*i*theta*(m-k)*l);
      end;
    end;
  end;
end;



