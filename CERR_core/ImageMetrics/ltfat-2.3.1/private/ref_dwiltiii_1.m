function [coef]=ref_dwiltiii_1(f,g,a,M)
%-*- texinfo -*-
%@deftypefn {Function} ref_dwiltiii_1
%@verbatim
%COMP_DWILT  Compute Discrete Wilson transform.
%   
%   Do not call this function directly, use DWILT instead.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_dwiltiii_1.html}
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

%   Author : Peter L. Soendergaard.

L=size(g,1);
N=L/a;
W=size(f,2);

c=ref_gdgt(f,g,a,2*M,0,.5,0);

coef2=reshape(c,2*M,N,W); % ----- Type III ------

coef=zeros(M,N,W);

if 0
  % --- Loop version ---
  for n=0:N-1
    for m=0:M-1
      if rem(m+n,2)==0
	coef(m+1,n+1,:)= 1/sqrt(2)*(exp(-i*pi/4)*coef2(m+1,n+1,:)+exp(i*pi/4)*coef2(2*M-m,n+1,:));
      else
	coef(m+1,n+1,:)= 1/sqrt(2)*(exp(i*pi/4)*coef2(m+1,n+1,:)+exp(-i*pi/4)*coef2(2*M-m,n+1,:));
      end;
    end;
  end;

else
  % --- Vector version---

  % --- m is even ---------
  coef(1:2:M,1:2:N,:)= 1/sqrt(2)*(exp(-i*pi/4)*coef2(1:2:M,1:2:N,:)+exp(i*pi/4)*coef2(2*M:-2:M+1,1:2:N,:));
  coef(1:2:M,2:2:N,:)= 1/sqrt(2)*(exp(i*pi/4)*coef2(1:2:M,2:2:N,:)+exp(-i*pi/4)*coef2(2*M:-2:M+1,2:2:N,:));
  
  % --- m is odd ----------
  coef(2:2:M,1:2:N,:)= 1/sqrt(2)*(exp(i*pi/4)*coef2(2:2:M,1:2:N,:)+exp(-i*pi/4)*coef2(2*M-1:-2:M+1,1:2:N,:));
  coef(2:2:M,2:2:N,:)= 1/sqrt(2)*(exp(-i*pi/4)*coef2(2:2:M,2:2:N,:)+exp(i*pi/4)*coef2(2*M-1:-2:M+1,2:2:N,:));

end;


coef=reshape(coef,M*N,W);






