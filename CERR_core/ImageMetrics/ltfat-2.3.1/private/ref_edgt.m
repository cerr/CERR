function c=ref_edgt(f,g,a,M)
%-*- texinfo -*-
%@deftypefn {Function} ref_edgt
%@verbatim
%REF_EDGT   Reference Even Discrete Gabor transform
%   Usage  c=ref_edgt(f,g,a,M);
%
%   The input window must be odd-centered.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_edgt.html}
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

N=L/a;
M=L/b;

F=zeros(L,M*N);

l=(0:L-1)';
for n=0:N-1
  for m=0:M-1
    F(:,1+m+n*M)=exp(2*pi*i*m.*(l+.5)*b/L).*circshift(g,n*a);
  end;
end;

c=F'*f;



