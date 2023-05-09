function c=ref_dcti(f)
%-*- texinfo -*-
%@deftypefn {Function} ref_dcti
%@verbatim
%REF_DCTI  Reference Discrete Consine Transform type I
%   Usage:  c=ref_dcti(f);
%
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_dcti.html}
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
  % Doing the algorithm explicitly for L=1 does a division by
  % zero, so we exit here instead.
  c=f;
  return;
end;

% Create weights.
w=ones(L,1);
w(1)=1/sqrt(2);
w(L)=1/sqrt(2);

% Create transform matrix.
F=zeros(L);

for m=0:L-1
  for n=0:L-1
    F(m+1,n+1)=w(n+1)*w(m+1)*cos(pi*n*m/(L-1));
  end;
end;

F=F*sqrt(2/(L-1));
% Compute coefficients.
c=F'*f;



