function c=ref_dwiltiii(f,g,a,M)
%-*- texinfo -*-
%@deftypefn {Function} ref_dwiltiii
%@verbatim
%REF_DWILTIII   Reference DWILT type III
%   Usage:  c=ref_dwiltiii(f,g,a,M);
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_dwiltiii.html}
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

% Possibly zero-extend the window if necessary.
g=fir2long(g,L);

N=L/a;

F=zeros(L,M*N);

l=(0:L-1)';

  
pif=pi/4;

if 0
  % This is the definition where the odd and even indices are split  
  for n=0:floor(N/2)-1
    for m=0:2:M-1
      F(:,1+m+2*n*M)=sqrt(2)*circshift(g,2*n*a).*cos((m+.5)*pi*l/M+pif);
      F(:,1+m+(2*n+1)*M)=sqrt(2)*circshift(g,(2*n+1)*a).*sin((m+.5)*pi*l/M+pif);
    end;
    for m=1:2:M-1
      F(:,1+m+2*n*M)=sqrt(2)*circshift(g,2*n*a).*sin((m+.5)*pi*l/M+pif);
      F(:,1+m+(2*n+1)*M)=sqrt(2)*circshift(g,(2*n+1)*a).*cos((m+.5)*pi*l/M+pif);
    end;
  end;
else
  % Combined definition

    % This is the definition where the odd and even indices are split  
  for n=0:N-1
    for m=0:M-1
      if rem(m+n,2)==0
        F(:,1+m+n*M)=sqrt(2)*circshift(g,n*a).*cos((m+.5)*pi*l/M+1/4*pi+(m+n)*pi);
      else
        F(:,1+m+n*M)=sqrt(2)*circshift(g,n*a).*cos((m+.5)*pi*l/M+3/4*pi+(m+n)*pi);
      end;
    end;
  end;
end;

c=F.'*f;




