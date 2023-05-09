function c=ref_rdftiii_1(f)
%-*- texinfo -*-
%@deftypefn {Function} ref_rdftiii_1
%@verbatim
%REF_RDFTIII_1  Reference RDFT by FFT
%   Usage:  c=ref_rdftiii_1(f);
%
%   Compute RDFTII by doing a DFTIII and returning half the coefficients.
%   Only works for real functions.
%
%   The transform is orthonormal
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_rdftiii_1.html}
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
Lend=Lhalf*2;

cc=ref_dftiii(f);

c=zeros(size(f));

% Copy the cosine-part of the coefficients.
c(1:2:Lend,:)=sqrt(2)*real(cc(1:Lhalf,:));

% Copy the sine-part of the coefficients.
c(2:2:Lend,:)=-sqrt(2)*imag(cc(1:Lhalf,:));

% If f has an odd length, we must also copy the Niquest-wave
% (it is real)
if mod(L,2)==1
  c(end,:)=real(cc((L+1)/2,:));
end;



