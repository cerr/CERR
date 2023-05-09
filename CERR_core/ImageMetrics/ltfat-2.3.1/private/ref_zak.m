function coef=ref_zak(f,K)
%-*- texinfo -*-
%@deftypefn {Function} ref_zak
%@verbatim
%REF_ZAK   Reference Zak-transform.
%   Usage:  c=ref_zak(f,K);
%
%   This function computes a reference Zak-transform by
%   an explicit summation.
%
%   It returns the coefficients in the rectangular layout.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_zak.html}
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

L=size(f,1);


% Slow, explicit method

% Workspace
coef=zeros(K,L/K);

for jj=0:K-1
  for kk=0:L/K-1
    for ll=0:L/K-1
      coef(jj+1,kk+1)=coef(jj+1,kk+1)+f(mod(jj-ll*K,L)+1)*exp(2*pi*i*kk*ll*K/L);
    end;
  end;
end;

coef=coef*sqrt(K/L);




