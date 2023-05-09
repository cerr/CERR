function c=ref_rdgt3(f,g,a,M)
%-*- texinfo -*-
%@deftypefn {Function} ref_rdgt3
%@verbatim
%REF_RDGT3  Reference Real DGT type 3
%   Usage:  c=ref_rdgtiii(f,g,a,M);
%
%   Linear algebra version of the algorithm. Create big matrix
%   containing all the basis functions and multiply with the transpose.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_rdgt3.html}
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

b=L/M;
N=L/a;

Mhalf=floor(M/2);

F=zeros(L,M*N);

l=(0:L-1).'/L;

for n=0:N-1
  
  for m=0:Mhalf-1
    F(:,M*n+2*m+1)=sqrt(2)*cos(2*pi*(m+.5)*b*l).*circshift(g,n*a);
    
    F(:,M*n+2*m+2)=sqrt(2)*sin(2*pi*(m+.5)*b*l).*circshift(g,n*a);
    
  end;

  if mod(M,2)==1
    F(:,M*(n+1))=cos(pi*L*l).*circshift(g,n*a);
  end;
  
end;

% dot-transpose will work because F is real.
c=F.'*f;



