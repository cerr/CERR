function f=comp_idgtreal_fac(coef,gf,L,a,M)
%-*- texinfo -*-
%@deftypefn {Function} comp_idgtreal_fac
%@verbatim
%COMP_IDGTREAL_FAC  Full-window factorization of a Gabor matrix assuming.
%   Usage:  f=comp_idgtreal_fac(c,gf,L,a,M)
%
%   Input parameters:
%         c     : M x N array of coefficients.
%         gf    : Factorization of window (from facgabm).
%         a     : Length of time shift.
%         M     : Number of frequency shifts.
%   Output parameters:
%         f     : Reconstructed signal.
%
%   Do not call this function directly, use IDGT.
%   This function does not check input parameters!
%
%   If input is a matrix, the transformation is applied to
%   each column.
%
%   This function does not handle multidimensional data, take care before
%   you call it.
%
%   References:
%     T. Strohmer. Numerical algorithms for discrete Gabor expansions. In
%     H. G. Feichtinger and T. Strohmer, editors, Gabor Analysis and
%     Algorithms, chapter 8, pages 267--294. Birkhauser, Boston, 1998.
%     
%     P. L. Soendergaard. An efficient algorithm for the discrete Gabor
%     transform using full length windows. IEEE Signal Process. Letters,
%     submitted for publication, 2007.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_idgtreal_fac.html}
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

%   AUTHOR : Peter L. Soendergaard.
%   TESTING: OK
%   REFERENCE: OK

% Calculate the parameters that was not specified.
N=L/a;
b=L/M;
M2=floor(M/2)+1;

R=prod(size(gf))/L;

%W=size(coef,2)/(N*R);
W = size(coef,3);

N=L/a;
b=L/M;

[c,h_a,h_m]=gcd(a,M);
h_a=-h_a;
p=a/c;
q=M/c;
d=N/q;

ff=zeros(p,q*W,c,d,assert_classname(coef,gf));
C=zeros(q*R,q*W,c,d,assert_classname(coef,gf));
f=zeros(L,W,assert_classname(coef,gf));

% Apply ifft to the coefficients.
coef=ifftreal(coef,M)*sqrt(M);
  
% Set up the small matrices

coef=reshape(coef,M,N,R,W);

if p==1

  for rw=0:R-1
    for w=0:W-1
      for s=0:d-1
	for l=0:q-1
	  for u=0:q-1
	    C(u+1+rw*q,l+1+w*q,:,s+1)=coef((1:c)+l*c,mod(u+s*q+l,N)+1,rw+1,w+1);
	  end;
	end;
      end;
    end;
  end;
else
  % Rational oversampling
  for rw=0:R-1
    for w=0:W-1
      for s=0:d-1
	for l=0:q-1
	  for u=0:q-1
	    C(u+1+rw*q,l+1+w*q,:,s+1)=coef((1:c)+l*c,mod(u+s*q-l*h_a,N)+1,rw+1,w+1);
	  end;
	end;
      end;
    end;
  end;
end;

% FFT them
if d>1
  C=fft(C,[],4);
end;

% Multiply them
for r=0:c-1    
  for s=0:d-1
    CM=reshape(C(:,:,r+1,s+1),q*R,q*W);
    GM=reshape(gf(:,r+s*c+1),p,q*R);

    ff(:,:,r+1,s+1)=GM*CM;
  end;
end;

% Inverse FFT
if d>1
  ff=ifft(ff,[],4);
end;

% Place the result  
if p==1

  for s=0:d-1
    for w=0:W-1
      for l=0:q-1
	f((1:c)+mod(s*M+l*a,L),w+1)=reshape(ff(1,l+1+w*q,:,s+1),c,1);
      end;
    end;
  end;

else
  % Rational oversampling
  for s=0:d-1
    for w=0:W-1
      for l=0:q-1
	for k=0:p-1
	  f((1:c)+mod(k*M+s*p*M-l*h_a*a,L),w+1)=reshape(ff(k+1,l+1+w*q,:,s+1),c,1);
	end;
      end;
    end;
  end;

end;

f=real(f);









