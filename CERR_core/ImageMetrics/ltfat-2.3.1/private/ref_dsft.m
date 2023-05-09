function C=ref_dsft(F)
%-*- texinfo -*-
%@deftypefn {Function} ref_dsft
%@verbatim
%REF_DSFT Reference DSFT
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_dsft.html}
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

%   AUTHOR : Peter L. Soendergaard

K=size(F,1);
L=size(F,2);

C=zeros(L,K);

for m=0:L-1
  for n=0:K-1
    for l=0:L-1
      for k=0:K-1
	C(m+1,n+1)=C(m+1,n+1)+F(k+1,l+1)*exp(2*pi*i*(k*n/K-l*m/L));
      end;
    end;
  end;
end;

C=C/sqrt(K*L);


