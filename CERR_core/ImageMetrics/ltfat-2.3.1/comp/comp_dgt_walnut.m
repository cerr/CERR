function cout=comp_dgt_walnut(f,gf,a,M)
%-*- texinfo -*-
%@deftypefn {Function} comp_dgt_walnut
%@verbatim
%COMP_DGT_WALNUT  First step of full-window factorization of a Gabor matrix.
%   Usage:  c=comp_dgt_walnut(f,gf,a,M);
%
%   Input parameters:
%         f      : Factored input data
%         gf     : Factorization of window (from facgabm).
%         a      : Length of time shift.
%         M      : Number of channels.
%   Output parameters:
%         c      : M x N*W*R array of coefficients, where N=L/a
%
%   Do not call this function directly, use DGT instead.
%   This function does not check input parameters!
%
%   The length of f and gamma must match.
%
%   If input is a matrix, the transformation is applied to
%   each column.
%
%   This function does not handle the multidim case. Take care before
%   calling this.
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
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_dgt_walnut.html}
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

L=size(f,1);
W=size(f,2);
LR=numel(gf);
R=LR/L;

N=L/a;

[c,h_a,h_m]=gcd(a,M);
h_a=-h_a;
p=a/c;
q=M/c;
d=N/q;

ff=zeros(p,q*W,c,d,assert_classname(f,gf));

if p==1
  % --- integer oversampling ---

  if (c==1) && (d==1) && (W==1) && (R==1)
    % --- Short time Fourier transform of single signal ---
    % This is used for spectrograms of short signals.      
      ff(1,:,1,1)=f(:);
  else
    for s=0:d-1
      for r=0:c-1    
	for l=0:q-1
	  ff(1,l+1:q:W*q,r+1,s+1)=f(r+s*M+l*c+1,:);
	end;
      end;
    end;    
  end;

else
  % --- rational oversampling ---
  % Set up the small matrices
  % The r-loop (runs up to c) has been vectorized
  for w=0:W-1
    for s=0:d-1
      for l=0:q-1
	for k=0:p-1	    	  
	  ff(k+1,l+1+w*q,:,s+1)=f((1:c)+mod(k*M+s*p*M-l*h_a*a,L),w+1);
	end;
      end;
    end;
  end;
end;

% This version uses matrix-vector products and ffts

% fft them
if d>1
  ff=fft(ff,[],4);
end;

C=zeros(q*R,q*W,c,d,assert_classname(f,gf));

for r=0:c-1    
  for s=0:d-1
    GM=reshape(gf(:,r+s*c+1),p,q*R);
    FM=reshape(ff(:,:,r+1,s+1),p,q*W);
    
    C(:,:,r+1,s+1)=GM'*FM;
  end;
end;

% Inverse fft
if d>1
  C=ifft(C,[],4);
end;

% Place the result

cout=zeros(M,N,R,W,assert_classname(f,gf));

if p==1
  % --- integer oversampling ---

  if (c==1) && (d==1) && (W==1) && (R==1)
    
    % --- Short time Fourier transform of single signal ---
    % This is used for spectrograms of short signals.      
    for l=0:q-1
      cout(l+1,mod((0:q-1)+l,N)+1,1,1)=C(:,l+1,1,1);
    end;
    
  else

    % The r-loop (runs up to c) has been vectorized
    for rw=0:R-1
      for w=0:W-1    
	for s=0:d-1
	  for l=0:q-1
	    for u=0:q-1
	      cout((1:c)+l*c,mod(u+s*q+l,N)+1,rw+1,w+1)=C(u+1+rw*q,l+1+w*q,:,s+1);
	    end;
	  end;
	end;
      end; 
    end;
  end;

else

  % Rational oversampling
  % The r-loop (runs up to c) has been vectorized
  for rw=0:R-1
    for w=0:W-1    
      for s=0:d-1
	for l=0:q-1
	  for u=0:q-1
	    cout((1:c)+l*c,mod(u+s*q-l*h_a,N)+1,rw+1,w+1)=C(u+1+rw*q,l+1+w*q,:,s+1);
	  end;
	end;
      end;
    end; 
  end;

end;

cout=reshape(cout,M,N*W*R);





