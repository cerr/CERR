function f=ref_iedgtii_1(c,g,a,M)
%-*- texinfo -*-
%@deftypefn {Function} ref_iedgtii_1
%@verbatim
%REF_EDGTII_1   Reference Inverse Even DGT type II by DGT
%   Usage  c=ref_edgt(f,g,a,M);
%
%   The input window must be odd-centered of length 2L.
%
%   a must be divisable by 2.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_iedgtii_1.html}
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

L=size(g,1)/2;
W=size(c,2);

N=L/a;

clong=zeros(M,2*N,W);

cr=reshape(c,M,N,W);
% Copy the first half unchanged
clong(:,1:N,:)=cr;

% Copy the non modulated coefficients.
clong(1,N+1:2*N,:)=cr(1,N:-1:1,:);

% Copy the modulated coefficients.
clong(2:M,N+1:2*N,:)=-cr(M:-1:2,N:-1:1,:);

clong=reshape(clong,2*M*N,W);

fdouble=ref_igdgt(clong,g,a,M,.5,0,floor(a/2));

f=fdouble(1:L,:);



