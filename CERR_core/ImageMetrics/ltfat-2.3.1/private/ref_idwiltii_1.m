function [f]=ref_idwiltii_1(coef,g,a,M)
%-*- texinfo -*-
%@deftypefn {Function} ref_idwiltii_1
%@verbatim
%REF_IDWILTII_1  Reference IDWILTII by IDGT type II
% 
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_idwiltii_1.html}
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

%   Author : Peter L. Soendergaard

L=size(g,1);
N=L/a;
W=size(coef,2);

coef=reshape(coef,M*2,N/2,W);

coef2=zeros(2*M,N,W);

if 0

  % --- loop version ---
  for n=0:N/2-1

    % m=0
    coef2(1,2*n+1,:) = coef(1,n+1,:);
  
    % m odd
    for m=1:2:M-1
      coef2(m+1,2*n+1,:)     = -i/sqrt(2)*coef(m+1,n+1,:);
      coef2(2*M-m+1,2*n+1,:) = -i/sqrt(2)*coef(m+1,n+1,:);
      
      coef2(m+1,2*n+2,:)     =  1/sqrt(2)*coef(M+m+1,n+1,:);
      coef2(2*M-m+1,2*n+2,:) = -1/sqrt(2)*coef(M+m+1,n+1,:);
    end;      
    
    % m even
    for m=2:2:M-1
      coef2(m+1,2*n+1,:)     =  1/sqrt(2)*coef(m+1,n+1,:);
      coef2(2*M-m+1,2*n+1,:) = -1/sqrt(2)*coef(m+1,n+1,:);
      
      coef2(m+1,2*n+2,:)     = -i/sqrt(2)*coef(M+m+1,n+1,:);
      coef2(2*M-m+1,2*n+2,:) = -i/sqrt(2)*coef(M+m+1,n+1,:);
    end;        

    % m=nyquest
    if mod(M,2)==0
      coef2(M+1,2*n+2,:) = -i*coef(M+1,n+1,:);
    else
      coef2(M+1,2*n+1,:) = -i*coef(M+1,n+1,:);
    end;

  end;

else

  % --- Vector version ---
  % First and middle modulation are transferred unchanged.
  coef2(1,1:2:N,:) = coef(1,:,:);

  coef2(2:2:M,1:2:N,:)        = -i/sqrt(2)*coef(2:2:M,:,:);
  coef2(2*M:-2:M+2,1:2:N,:)   = -i/sqrt(2)*coef(2:2:M,:,:);
  
  coef2(2:2:M,2:2:N,:)        =  1/sqrt(2)*coef(M+2:2:2*M,:,:);
  coef2(2*M:-2:M+2,2:2:N,:)   = -1/sqrt(2)*coef(M+2:2:2*M,:,:);

  if M>2
    coef2(3:2:M,1:2:N,:)        = 1/sqrt(2)*coef(3:2:M,:,:);
    coef2(2*M-1:-2:M+2,1:2:N,:) = -1/sqrt(2)*coef(3:2:M,:,:);
    
    coef2(3:2:M,2:2:N,:)        = -i/sqrt(2)*coef(M+3:2:2*M,:,:);
    coef2(2*M-1:-2:M+2,2:2:N,:) = -i/sqrt(2)*coef(M+3:2:2*M,:,:);
  end;

  if mod(M,2)==0
    coef2(M+1,2:2:N,:) = -i*coef(M+1,:,:);
  else
    coef2(M+1,1:2:N,:) = -i*coef(M+1,:,:);
  end;

  
end;


f=ref_igdgt(reshape(coef2,2*M*N,W),g,a,2*M,.5,0,0);

%if norm(imag(f(:)))<1e-10
%  f=real(f);
%end;


