function c=ref_dwiltiv(f,g,a,M)
%REF_DWILTIV   Reference DWILT type iv
%   Usage:  c=ref_dwiltiv(f,g,a,M);
%
%
%   Url: http://ltfat.github.io/doc/reference/ref_dwiltiv.html

% Copyright (C) 2005-2022 Peter L. Soendergaard <peter@sonderport.dk> and others.
% This file is part of LTFAT version 2.5.0
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

N=L/a;

F=zeros(L,M*N);

k=(0:L-1)';

pif=pi/4;
for n=0:floor(N/2)-1
  for m=0:2:M-1
    F(:,1+m+2*n*M)=sqrt(2)*circshift(g,2*n*a).*cos((m+.5)*pi*(k+.5)/M+pif);
    F(:,1+m+(2*n+1)*M)=sqrt(2)*circshift(g,(2*n+1)*a).*sin((m+.5)*pi*(k+.5)/M+pif);
  end;
  for m=1:2:M-1
    F(:,1+m+2*n*M)=sqrt(2)*circshift(g,2*n*a).*sin((m+.5)*pi*(k+.5)/M+pif);
    F(:,1+m+(2*n+1)*M)=sqrt(2)*circshift(g,(2*n+1)*a).*cos((m+.5)*pi*(k+.5)/M+pif);
  end;
end;

c=F.'*f;



