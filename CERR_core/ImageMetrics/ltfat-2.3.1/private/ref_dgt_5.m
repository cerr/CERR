function coef=ref_dgt_5(f,g,a,M)
%-*- texinfo -*-
%@deftypefn {Function} ref_dgt_5
%@verbatim
%REF_DGT_5  DGT algorithm 5
%
%  This algorithm uses explicit convolution inside the loops.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_dgt_5.html}
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
  % As ref_dgt_2, but substitution mt=k+st*p
  % and                            n =u+s*q
  % and apply reductions as described in the paper.
  for r=0:c-1    
    for l=0:q-1
      for u=0:q-1
        for k=0:p-1            
          for s=0:d-1
            for st=0:d-1
              w(r+l*c+1,mod(u+s*q-l*h_a,N)+1)=w(r+l*c+1,mod(u+s*q-l*h_a,N)+1)+f(mod(r+k*M+st*p*M-l*h_a*a,L)+1)*...
                  conj(g(mod(r+k*M-u*a+(st-s)*p*M,L)+1));
            end;
          end;
        end;
      end;
    end;    
  end;
end;

if 1

  % As above, but the inner convolution is now explicitly expressed
  for r=0:c-1    
    for l=0:q-1
      for u=0:q-1
        for k=0:p-1     
          psi=zeros(d,1);
          phi=zeros(d,1);
          for s=0:d-1
            psi(s+1)=f(mod(r+k*M+s*p*M-l*h_a*a,L)+1);              
            phi(s+1)=g(mod(r+k*M-u*a+s*p*M,L)+1);
          end;
              
          innerconv = pconv(psi,phi,'r');
          
          for s=0:d-1
            w(r+l*c+1,mod(u+s*q-l*h_a,N)+1)=w(r+l*c+1,mod(u+s*q-l*h_a,N)+1)+innerconv(s+1);
          end;
        end;
      end;
    end;    
  end;
  
  coef=fft(w);    
end;

  
  
  
  
  
  


