function f=ref_idwilt(c,g,a,M)
%-*- texinfo -*-
%@deftypefn {Function} ref_idwilt
%@verbatim
%REF_DWILT  Reference Inverse Discrete Wilson Transform
%   Usage:  f=ref_idwilt(c,g,a,M);
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_idwilt.html}
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
N=L/a;

F=zeros(L,M*N);



% Weight coefficients.

l=(0:L-1).';

pif=0;

if 1
  % This version uses sines and cosines to express the basis functions.

  for n=0:N/2-1    
    % Do the unmodulated coefficient.
    F(:,2*M*n+1)=circshift(g,2*a*n);
    
    % Setting this to -n*a should produce a time-invariant transform.
    timeinv=0; %-n*a;
    
    % m odd case
    for m=1:2:M-1
      F(:,m+2*M*n+1)   = sqrt(2)*sin(pi*m/M*(l+timeinv)+pif).*circshift(g,2*n*a);
      F(:,m+2*M*n+M+1) = sqrt(2)*cos(pi*m/M*(l+timeinv)+pif).*circshift(g,(2*n+1)*a);
    end;
    
    % m even case
    for m=2:2:M-1
      F(:,m+2*M*n+1)     = sqrt(2)*cos(pi*m/M*(l+timeinv)+pif).*circshift(g,2*n*a);
      F(:,m+2*M*n+M+1)   = sqrt(2)*sin(pi*m/M*(l+timeinv)+pif).*circshift(g,(2*n+1)*a);
    end;
    
    % Most modulated coefficient, Nyquest frequency.
    if mod(M,2)==0
      F(:,M+2*M*n+1)=(-1).^(l+timeinv).*circshift(g,2*n*a);
    else
      F(:,M+2*M*n+1)=(-1).^(l+timeinv).*circshift(g,(2*n+1)*a);
    end;
  end;

else

  % This version uses a cosine, 

  for n=0:N/2-1    
    % Do the unmodulated coefficient.
    F(:,2*M*n+1)=circshift(g,2*a*n);
    
    timeinv=-n*a;
    
    % m odd case
    for m=1:2:M-1
      F(:,m+2*M*n+1)   = sqrt(2)*cos(pi*m/M*(l+timeinv-M/2)+pif).*circshift(g,2*n*a);
      F(:,m+2*M*n+M+1) = sqrt(2)*sin(pi*m/M*(l+timeinv-M/2-a)+pif).*circshift(g,(2*n+1)*a);
    end;
    
    % m even case
    for m=2:2:M-1
      F(:,m+2*M*n+1)     = sqrt(2)*cos(pi*m/M*(l+timeinv-M/2)+pif).*circshift(g,2*n*a);
      F(:,m+2*M*n+M+1)   = sqrt(2)*sin(pi*m/M*(l+timeinv-M/2-a)+pif).*circshift(g,(2*n+1)*a);
    end;
    
    % Most modulated coefficient, Nyquest frequency.
    if mod(M,2)==0
      F(:,M+2*M*n+1)=(-1).^(l+timeinv).*circshift(g,2*n*a);
    else
      F(:,M+2*M*n+1)=(-1).^(l+timeinv-a).*circshift(g,(2*n+1)*a);
    end;
  end;



end;

f=F*c;


