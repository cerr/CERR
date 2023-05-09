function [g]=ref_iwfac(gf,L,a,M)
%-*- texinfo -*-
%@deftypefn {Function} ref_iwfac
%@verbatim
%REF_IWFAC  Compute inverse window factorization
%   Usage: g=ref_iwfac(gf,L,a,M);
%
%   Input parameters:
%         gf    : Factored Window
%         L     : Length of transform.
%         a     : Length of time shift.
%         M     : Number of frequency bands.
%   Output parameters:
%         g     : Window function.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_iwfac.html}
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

% Calculate the parameters that was not specified
R=prod(size(gf))/L;

N=L/a;
b=L/M;

% The four factorization parameters.
c=gcd(a,M);
p=a/c;
q=M/c;
d=N/q;

gf=reshape(gf,p,q*R,c,d);

% Scale by the sqrt(M) comming from Walnuts representation
gf=gf/sqrt(M);


% fft them
if d>1
  gf=ifft(gf,[],4);
end;

g=zeros(L,R);

% Set up the small matrices
for w=0:R-1
  for s=0:d-1
    for l=0:q-1
      for k=0:p-1
	g((1:c)+mod(k*M-l*a+s*p*M,L),w+1)=gf(k+1,l+1+q*w,:,s+1);
      end;
    end;
  end;
end;



