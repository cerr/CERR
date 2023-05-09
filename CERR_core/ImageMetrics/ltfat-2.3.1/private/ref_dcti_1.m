function c=ref_dcti_1(f)
%-*- texinfo -*-
%@deftypefn {Function} ref_dcti_1
%@verbatim
%REF_DCTI_1  Reference Discrete Consine Transform type I
%   Usage:  c=ref_dcti_1(f);
%
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_dcti_1.html}
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

if L==1
  c=f;
  return;
end;

R=1/sqrt(2)*[eye(L);...
	     [zeros(L-2,1),flipud(eye(L-2)),zeros(L-2,1)]];

R(1,1)=1;
R(L,L)=1;

c=R'*dft(R*f);




