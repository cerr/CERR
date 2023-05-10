function gf=comp_wfac(g,a,M)
%COMP_WFAC  Compute window factorization
%  Usage: gf=comp_wfac(g,a,M);
%
%   References:
%     T. Strohmer. Numerical algorithms for discrete Gabor expansions. In
%     H. G. Feichtinger and T. Strohmer, editors, Gabor Analysis and
%     Algorithms, chapter 8, pages 267--294. Birkhäuser, Boston, 1998.
%     
%     P. L. Søndergaard. An efficient algorithm for the discrete Gabor
%     transform using full length windows. IEEE Signal Process. Letters,
%     submitted for publication, 2007.
%     
%
%   Url: http://ltfat.github.io/doc/comp/comp_wfac.html

% Copyright (C) 2005-2022 Peter L. Soendergaard <peter@sonderport.dk> and others.
% This file is part of LTFAT version 2.5.0
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

%   AUTHOR : Peter L. Søndergaard.
%   TESTING: OK
%   REFERENCE: OK
  
L=size(g,1);
R=size(g,2);

N=L/a;
b=L/M;

c=gcd(a,M);
p=a/c;
q=M/c;
d=N/q;

gf=zeros(p,q*R,c,d,assert_classname(g));

% Set up the small matrices
% The w loop is only used for multiwindows, which should be a rare occurence.
% Therefore, we make it the outermost
if p==1  
  % Integer oversampling
  if (c==1) && (d==1) && (R==1)
    % --- Short time Fourier transform of single signal ---
    % This is used for spectrograms of short signals.            
    for l=0:q-1	  
      gf(1,l+1,1,1)=g(mod(-l,L)+1);
    end;

  else

    for w=0:R-1
      for s=0:d-1
	for l=0:q-1	  
	  gf(1,l+1+q*w,:,s+1)=g((1:c)+mod(-l*a+s*p*M,L),w+1);
	end;
      end;
    end;

  end;
else
  % Rational oversampling

  for w=0:R-1
    for s=0:d-1
      for l=0:q-1
	for k=0:p-1	    
	  gf(k+1,l+1+q*w,:,s+1)=g((1:c)+c*mod(k*q-l*p+s*p*q,d*p*q),w+1);
	end;
      end;
    end;
  end;

end;

% dft them
if d>1
  gf=fft(gf,[],4);
end;

% Scale by the sqrt(M) comming from Walnuts representation
gf=gf*sqrt(M);

gf=reshape(gf,p*q*R,c*d);


