function gf=ref_wfac(g,a,M)
%-*- texinfo -*-
%@deftypefn {Function} ref_wfac
%@verbatim
%REF_WFAC  Compute window factorization
%  Usage: gf=ref_wfac(g,a,M);
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_wfac.html}
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

% The commented _nos code in this file can be used to test
% the _nos versions of the C-library.

L=size(g,1);
R=size(g,2);

N=L/a;
b=L/M;

c=gcd(a,M);
p=a/c;
q=M/c;
d=N/q;

gf=zeros(p,q*R,c,d);
gf_nos=zeros(d,p,q*R,c);

for w=0:R-1
  for s=0:d-1
    for l=0:q-1
      for k=0:p-1	    
	gf(k+1,l+1+q*w,:,s+1)=g((1:c)+c*mod(k*q-l*p+s*p*q,d*p*q),w+1);
	%gf_nos(s+1,k+1,l+1+q*w,:)=g((1:c)+c*mod(k*q-l*p+s*p*q,d*p*q),w+1);
      end;
    end;
  end;
end;

% dft them
if d>1
  gf=fft(gf,[],4);
  %gf_nos=fft(gf_nos);
end;

% Scale by the sqrt(M) comming from Walnuts representation
gf=gf*sqrt(M);
%gf_nos=gf_nos*sqrt(M);

%gf_nos=permute(gf_nos,[2, 3, 4, 1]);

%norm(gf_nos(:)-gf(:))

gf=reshape(gf,p*q*R,c*d);


