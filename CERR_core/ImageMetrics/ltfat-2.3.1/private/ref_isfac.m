function [f]=ref_isfac(ff,L,a,M)
%-*- texinfo -*-
%@deftypefn {Function} ref_isfac
%@verbatim
%REF_ISFAC  Reference inverse signal factorization
%   Usage: f=ref_sfac(ff,a,M);
%
%   Input parameters:
%         ff    : Factored signal
%         a     : Length of time shift.
%         b     : Length of frequency shift.
%   Output parameters:
%         f     : Output signal.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_isfac.html}
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
W=prod(size(ff))/L;

N=L/a;
M=L/b;

% The four factorization parameters.
[c,h_a,h_m]=gcd(a,M);
p=a/c;
q=M/c;
d=N/q;

permutation=zeros(q*b,1);
P=stridep(p,b);

% Create permutation
for l=0:q-1
  for s=0:b-1
    permutation(l*b+1+s)=mod(P(s+1)-1-h_m*l,b)*M+l*c+1;
  end;
end;

f=ref_ifac(ff,W,c,d,p,q,permutation);



