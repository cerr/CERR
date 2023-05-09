function f=ref_irdgtii(c,g,a,M)
%-*- texinfo -*-
%@deftypefn {Function} ref_irdgtii
%@verbatim
%REF_IRDGTII  Reference Inverse Real DGT type II
%   Usage:  c=ref_rdgt(f,g,a,M);
%
%   Linear algebra version of the algorithm. Create big matrix
%   containing all the basis functions and multiply with the transpose.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_irdgtii.html}
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

L=size(g,1);

b=L/M;
N=L/a;

Mhalf=ceil(M/2);


F=zeros(L,M*N);

l=(0:L-1).';

for n=0:N-1

  % Do the unmodulated coefficient.
  F(:,M*n+1)=circshift(g,n*a+floor(a/2));
  
  for m=1:Mhalf-1
    F(:,M*n+2*m)=sqrt(2)*cos(2*pi*m*(l+.5)/M).*circshift(g,n*a+floor(a/2));;
    
    F(:,M*n+2*m+1)=sqrt(2)*sin(2*pi*m*(l+.5)/M).*circshift(g,n*a+floor(a/2));;
    
  end;

  if mod(M,2)==0
    F(:,M*(n+1))=cos(pi*l).*circshift(g,n*a+floor(a/2));;
  end;
  
end;

% dot-transpose will work because F is real.
f=F*c;



