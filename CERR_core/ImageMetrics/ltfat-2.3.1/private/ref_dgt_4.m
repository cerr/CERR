function c=ref_dgt_4(f,g,a,M)
%-*- texinfo -*-
%@deftypefn {Function} ref_dgt_4
%@verbatim
%REF_DGT_4  DGT algorithm 4
%
%  This algorithm makes the r-loop be the outermost loop, in order to
%  reduce the size of the intermediate buffers, and hopefully better
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_dgt_4.html}
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

% This version uses matrix-vector products and ffts

F=zeros(d,p,q);

C=zeros(d,q,q);

% Setup G before we start
G=zeros(c,d,p,q);
for r=0:c-1    
  for s=0:d-1
    for k=0:p-1
      for l=0:q-1
        G(r+1,s+1,k+1,l+1)=sqrt(M*d)*g(mod(r+k*M-l*a+s*p*M,L)+1);
      end;
    end;
  end;  
end;
G=dft(G,[],2);

% Set up the matrices
for r=0:c-1    

  
  for s=0:d-1
    for k=0:p-1
      for l=0:q-1
        F(s+1,k+1,l+1)=f(mod(r+k*M+s*p*M-l*h_a*a,L)+1);
      end;
    end;
  end;
  
  
  % fft them
  F=dft(F,[],1);
  
  
  % Multiply them
  for s=0:d-1
    GM=reshape(G(r+1,s+1,:,:),p,q);
    FM=reshape(F(s+1,:,:),p,q);
    C(s+1,:,:)=GM'*FM;
  end;

  % Inverse fft
  C=idft(C,[],1);

  % Place the result
  for l=0:q-1
    for u=0:q-1
      for s=0:d-1
        w(r+l*c+1,mod(u+s*q-l*h_a,N)+1)=C(s+1,u+1,l+1);
      end;
    end;
  end;   
end;

c=dft(w);

  
  
  


