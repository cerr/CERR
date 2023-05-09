function c=ref_dgt_1(f,g,a,M)
%-*- texinfo -*-
%@deftypefn {Function} ref_dgt_1
%@verbatim
%REF_DGT_1  DGT by Poisson summation.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_dgt_1.html}
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

L=size(g,1);
N=L/a;
b=L/M;

w=zeros(M,N);

if 0
  
  % This version uses the definition
  
  for jj=0:M-1  
    for nn=0:N-1
      for kk=0:b-1
	w(jj+1,nn+1)=w(jj+1,nn+1)+f(jj+kk*M+1)*conj(g(mod(jj+kk*M-nn*a,L)+1));
      end;
    end;
  end;

else

  % This version uses matrix-vector products.
  
  W=zeros(b,N);
  v=zeros(b,1);
  for jj=0:M-1

    % Setup the matrix and vector
    for kk=0:b-1
      for nn=0:N-1
	W(kk+1,nn+1)=g(mod(jj+kk*M-nn*a,L)+1);
      end;

      v(kk+1)=f(mod(jj+kk*M,L)+1);
    end;

    % do the product.
    s1=W'*v;

    % Arrange in w
    for nn=0:N-1
      w(jj+1,nn+1)=s1(nn+1);
    end;
   
  end;


end;

c=fft(w);



