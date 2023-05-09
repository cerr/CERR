function c=ref_rdgt3_1(f,g,a,M)
%-*- texinfo -*-
%@deftypefn {Function} ref_rdgt3_1
%@verbatim
%REF_RDGT3_1  Reference Real DGT type 3
%   Usage:  c=ref_rdgt3_1(f,g,a,M);
%
%   Compute a DGT3 and pick out the coefficients
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_rdgt3_1.html}
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
R=size(g,2);

N=L/a;

Mhalf=floor(M/2);

cc=ref_gdgt(f,g,a,M,0,.5,0);
cc=reshape(cc,M,N,W);

c=zeros(M,N,W);

for m=0:Mhalf-1
  c(2*m+1,:,:)=sqrt(2)*real(cc(m+1,:,:));
  c(2*m+2,:,:)=-sqrt(2)*imag(cc(m+1,:,:));
end;

if mod(M,2)==1
  c(M,:,:)=cc((M+1)/2,:,:);
end;

c=reshape(c,M*N,W);



