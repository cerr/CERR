function fout=ref_spreadop_1(f,c,a);
%-*- texinfo -*-
%@deftypefn {Function} ref_spreadop_1
%@verbatim
%REF_SPREADOP_1  Ref. Spreading function
%   Usage: h=ref_spreadfun_1(f,c,a);
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_spreadop_1.html}
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

%XXX Wrong sign convention
  
W=size(f,2);
M=size(c,1);
N=size(c,2);
L=N*a; 

[c,h_a,h_m]=gcd(a,M);
h_a=-h_a;
p=a/c;
q=M/c;
d=N/q;

fout=zeros(L,W);

cf1=fft(coef);

for j=0:M-1
  for m=0:b-1    
    for n=0:N-1
      fout(j+m*M+1,:)=fout(j+m*M+1,:)+cf1(j+1,n+1)*f(mod(j+m*M-n*a,L)+1,:);
    end;
  end;
end;




