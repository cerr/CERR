function c=ref_fcdgt(f,g,a,M,m_t,m_f,w_t,w_f)
%-*- texinfo -*-
%@deftypefn {Function} ref_fcdgt
%@verbatim
%REF_CDGT  Reference centered DGT
%   Usage:  c=ref_dgtiv(f,g,a,M,c_t,c_f,c_w);
%
%   Linear algebra version of the algorithm. Create big matrix
%   containing all the basis functions and multiply with the transpose.
%
%   For easy work, m_t,m_f,w_t,w_f are all just 0/1 indicator variables.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_fcdgt.html}
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
N=L/a;
b=L/M;

m_t=m_t*.5;
w_t=w_t*floor(a/2);
w_f=w_f*ceil(b/2);


F=zeros(L,M*N);

l=(0:L-1).';

if m_f==0

  for n=0:N-1	   
    for m=0:M-1
      F(:,M*n+m+1)=exp(2*pi*i*(m*b+w_f)*(l+m_t)/L).*circshift(g,n*a+w_t);
    end;
  end;

else

  for n=0:N-1	   
    for m=0:M-1
      F(:,M*n+m+1)=exp(2*pi*i*(m*b+.5+w_f)*(l+m_t-n*a)/L).*circshift(g,n*a+w_t);
    end;
  end;


end;

c=F'*f;




