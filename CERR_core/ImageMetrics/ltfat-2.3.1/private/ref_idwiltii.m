function f=ref_idwiltii(c,g,a,M)
%-*- texinfo -*-
%@deftypefn {Function} ref_idwiltii
%@verbatim
%REF_DWILTII  Reference Inverse Discrete Wilson Transform type II
%   Usage:  f=ref_idwiltii(c,g,M);
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_idwiltii.html}
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

% Setup transformation matrix.

L=size(g,1);
W=size(c,2);

F=zeros(L,L);

N=L/a;

l=(0:L-1).';

for n=0:N/2-1    
  % Do the unmodulated coefficient.
  F(:,2*M*n+1)=circshift(g,2*a*n); 
  
  % m odd case OK
  for m=1:2:M-1
    F(:,m+2*M*n+1) = sqrt(2)*sin(pi*m/M*(l+.5)).*circshift(g,2*n*a);
    F(:,m+2*M*n+M+1) = sqrt(2)*cos(pi*m/M*(l+.5)).*circshift(g,(2*n+1)*a);
  end;

  for m=2:2:M-1
    F(:,m+2*M*n+1) = sqrt(2)*cos(pi*m/M*(l+.5)).*circshift(g,2*n*a);
    F(:,m+2*M*n+M+1) = sqrt(2)*sin(pi*m/M*(l+.5)).*circshift(g,(2*n+1)*a);
  end;

  if rem(M,2)==0
    % Do the Nyquest wave.
    F(:,M+2*M*n+1)   = sin(pi*(l+.5)).*circshift(g,(2*n+1)*a); 
  else
    F(:,M+2*M*n+1)   = sin(pi*(l+.5)).*circshift(g,2*n*a); 
  end;     
  
end;

f=F*c;


