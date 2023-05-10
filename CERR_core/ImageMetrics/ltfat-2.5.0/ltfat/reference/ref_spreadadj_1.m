function cadj=ref_spreadadj_1(coef);
%REF_SPREADADJ  Symbol of adjoint preading function.
%   Usage: cadj=ref_spreadadj_1(c);
%
%   cadj=SPREADADJ(c) will compute the symbol cadj of the spreading
%   operator that is the adjoint of the spreading operator with symbol c.
%
%   The algorithm uses an explit algorithm to compute the entries.
%
%   Url: http://ltfat.github.io/doc/reference/ref_spreadadj_1.html

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
  

L=size(coef,1);

cadj=zeros(L);
for ii=0:L-1
  for jj=0:L-1
    cadj(ii+1,jj+1)=conj(coef(mod(L-ii,L)+1,mod(L-jj,L)+1))...
        *exp(-i*2*pi*ii*jj/L);
  end;
end;





