function f=ref_irdgt3_1(c,g,a,M)
%-*- texinfo -*-
%@deftypefn {Function} ref_irdgt3_1
%@verbatim
%REF_IRDGT3_1  Reference Inverse Real DGT type 3 by IDGT3
%   Usage:  f=ref_irdgt3_1(c,g,a,M);
%
%   Compute a complex coefficient layout for IDGT3
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_irdgt3_1.html}
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
W=size(c,2);
R=size(g,2);

b=L/M;
N=L/a;

Mhalf=floor(M/2);

c=reshape(c,M,N,W);
cc=zeros(M,N,W);

for m=0:Mhalf-1
  cc(m+1,:,:)=1/sqrt(2)*(c(2*m+1,:,:)-i*c(2*m+2,:,:));
  cc(M-m,:,:)=1/sqrt(2)*(c(2*m+1,:,:)+i*c(2*m+2,:,:));
end;

if mod(M,2)==1
  cc((M+1)/2,:,:)=c(M,:,:);
end;

cc=reshape(cc,M*N,W);

f=ref_igdgt(cc,g,a,M,0,.5,0);






