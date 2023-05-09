function c=ref_dgt_3(f,g,a,M)
%-*- texinfo -*-
%@deftypefn {Function} ref_dgt_3
%@verbatim
%REF_DGT_3  DGT algorithm 3
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_dgt_3.html}
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

if 0

  % This version uses the definition.

  F=zeros(c,d,p,q);
  G=zeros(c,d,p,q);
  
  for r=0:c-1    
    for s=0:d-1
      for k=0:p-1
	for l=0:q-1
	  for st=0:d-1
	    F(r+1,s+1,k+1,l+1)=F(r+1,s+1,k+1,l+1)+f(mod(r+k*M+st*p*M-l*h_a*a,L)+1)*exp(-2*pi*i*s*st/d);
	    G(r+1,s+1,k+1,l+1)=G(r+1,s+1,k+1,l+1)+g(mod(r+k*M-l*a+st*p*M,L)+1)*exp(-2*pi*i*s*st/d);
	  end;
	end;
      end;
    end;
  end;

 for r=0:c-1    
    for l=0:q-1
      for u=0:q-1
	for s=0:d-1
	  for v=0:d-1
	    for k=0:p-1
	      w(r+l*c+1,mod(u+s*q-l*h_a,N)+1)=w(r+l*c+1,mod(u+s*q-l*h_a,N)+1)+...
		  1/d*F(r+1,v+1,k+1,l+1)*conj(G(r+1,v+1,k+1,u+1))*exp(2*pi*i*v*s/d);
	    end;
	  end;
	end;
      end;
    end;
  end;
  

else

  % This version uses matrix-vector products and ffts

  F=zeros(c,d,p,q);
  G=zeros(c,d,p,q);
  C=zeros(c,d,q,q);
  
  % Set up the matrices
  for r=0:c-1    
    for s=0:d-1
      for k=0:p-1
	for l=0:q-1
	  F(r+1,s+1,k+1,l+1)=f(mod(r+k*M+s*p*M-l*h_a*a,L)+1);
	  G(r+1,s+1,k+1,l+1)=sqrt(M*d)*g(mod(r+k*M-l*a+s*p*M,L)+1);
	end;
      end;
    end;
  end;

  % fft them
  F=dft(F,[],2);
  G=dft(G,[],2);
  
  % Multiply them
  for r=0:c-1    
    for s=0:d-1
      GM=reshape(G(r+1,s+1,:,:),p,q);
      FM=reshape(F(r+1,s+1,:,:),p,q);
      C(r+1,s+1,:,:)=GM'*FM;
    end;
  end;

  % Inverse fft
  C=idft(C,[],2);

  % Place the result
  for r=0:c-1    
    for l=0:q-1
      for u=0:q-1
	for s=0:d-1
	  w(r+l*c+1,mod(u+s*q-l*h_a,N)+1)=C(r+1,s+1,u+1,l+1);
	end;
      end;
    end;
  end; 
  
end;

c=dft(w);



