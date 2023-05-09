function f=ref_iedgt(c,g,a,M)
%-*- texinfo -*-
%@deftypefn {Function} ref_iedgt
%@verbatim
%REF_IEDGT   Reference Inverse Even DGT
%   Usage  f=ref_edgt(c,g,a,M);
%
%   The input window must be odd-centered of length 2L.
%   
%   M must be even.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_iedgt.html}
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

L2=size(g,1);
W=size(c,2);
L=L2/2;

M=L/b;
N=L/a;

F=zeros(L,M*N);

l=(0:L-1).';

lsecond=(2*L-1:-1:L).';

for m=0:M/2-1
  F(:,m+1) = exp(2*pi*i*m*b*(l+.5)/L).*g(l+1) + ...
      exp(-2*pi*i*m*b*(l+.5)/L).*g(lsecond+1);

  gshift=circshift(g,L);

  F(:,m+1+M*(N-1)+M/2) = exp(2*pi*i*m*b*(l+.5)/L).*gshift(l+1) + ...
      exp(-2*pi*i*m*b*(l+.5)/L).*gshift(lsecond+1);
  
end;

% Scale the first modulations correctly
F(:,1)=F(:,1)/sqrt(2);
F(:,M*(N-1)+M/2+1)=F(:,M*(N-1)+M/2+1)/sqrt(2);


%for n=0:N-1	   
%  for m=0:M-1
%    gshift=circshift(gnew,n*a);

%    F(:,M*n+m+1)=exp(2*pi*i*m*b*(l+.5)/L).*gshift(l+1) + ...
%	exp(-2*pi*i*m*b*(l+.5)/L).*gshift(lsecond+1);

%  end;
%end;

f=F*c;



