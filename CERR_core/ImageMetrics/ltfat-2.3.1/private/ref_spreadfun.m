function coef=ref_spreadfun(T)
%-*- texinfo -*-
%@deftypefn {Function} ref_spreadfun
%@verbatim
%REF_SPREADFUN  Spreading function.
%   Usage:  c=ref_spreadfun(T);
%
%   REF_SPREADFUN(T) computes the spreading function of the operator T. The
%   spreading function represent the operator T as a weighted sum of
%   time-frequency shifts. See the help text for SPREADOP for the exact
%   definition.
%
%   SEE ALSO:  SPREADOP, TCONV, SPREADINV, SPREADADJ
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_spreadfun.html}
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

L=size(T,1);

coef=zeros(L);
for ii=0:L-1
  for jj=0:L-1
    coef(ii+1,jj+1)=T(ii+1,mod(ii-jj,L)+1);
  end;
end;

coef=fft(coef)/L;




