function fout=ref_spreadop(f,c,a);
%-*- texinfo -*-
%@deftypefn {Function} ref_spreadop
%@verbatim
%REF_SPREADOP  Reference Spreading operator.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_spreadop.html}
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


W=size(f,2);
M=size(c,1);
N=size(c,2);
L=N*a;

fout=zeros(L,W,assert_classname(f,c));

for l=0:L-1
  for m=0:M-1
    for n=0:N-1
      fout(l+1,:)=fout(l+1,:)+c(m+1,n+1)*exp(2*pi*i*l*m/M)*f(mod(l-n*a,L)+1,:);
    end;
  end;
end;



