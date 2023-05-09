function c=ref_dgt_2(f,g,a,M)
%-*- texinfo -*-
%@deftypefn {Function} ref_dgt_2
%@verbatim
%REF_DGT_2  DGT algorithm 2
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_dgt_2.html}
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

[c,h_a,h_m]=gcd(-a,M);
p=a/c;
q=M/c;
d=N/q;

w=zeros(M,N);

% mt = m-tilde

if 0
  
  % This version uses the definition  
  for r=0:c-1    
    for l=0:q-1
      for n=0:N-1
	for mt=0:b-1
	  w(r+l*c+1,mod(n-l*h_a,N)+1)=w(r+l*c+1,mod(n-l*h_a,N)+1)+f(mod(r+l*c+(mt-l*h_m)*M,L)+1)*...
	      conj(g(mod(r+mt*M-n*a,L)+1));
	end;
      end;
    end;    
  end;

else

  % This version uses matrix-vector products.
  
  W=zeros(b,N);
  V=zeros(b,q);
  for r=0:c-1
    
    % Setup the matrix and vector
    for mt=0:b-1
      for n=0:N-1
	W(mt+1,n+1)=g(mod(r+mt*M-n*a,L)+1);
      end;
      
      for l=0:q-1
	V(mt+1,l+1)=f(mod(r+mt*M+l*(c-h_m*M),L)+1);
      end;
    end;
    
    % do the product.
    s1=W'*V;
    
    % Arrange in w
    for n=0:N-1
      for l=0:q-1
	w(r+l*c+1,mod(n-l*h_a,N)+1)=s1(n+1,l+1);
      end;
    end;
    
  end;

end;


c=fft(w);



