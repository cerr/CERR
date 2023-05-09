function c=ref_rdftiii(f)
%-*- texinfo -*-
%@deftypefn {Function} ref_rdftiii
%@verbatim
%REF_RDFTIII  Reference Real DFT type III
%   Usage:  c=ref_rdftiii(f);
%
%   Compute RDFTIII by explicit formulas.
%
%   The transform is orthonormal
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_rdftiii.html}
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
Lhalf=floor(L/2);

F=zeros(L);

F(:,1)=ones(L,1);

l=(0:L-1).'/L;
for m=0:Lhalf-1
  F(:,2*m+1)=sqrt(2)*cos(2*pi*(m+.5)*l);

  F(:,2*m+2)=sqrt(2)*sin(2*pi*(m+.5)*l);
end;

if mod(L,2)==1
  F(:,L)=cos(pi*L*l);
end;

F=F/sqrt(L);

% dot-transpose will work because F is real.
c=F.'*f;




