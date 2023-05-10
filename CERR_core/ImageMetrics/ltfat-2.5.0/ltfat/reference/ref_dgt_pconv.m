function c=ref_dgt_pconv(f,g,a,M);
%REF_DGT_PCONV  Compute a DGT using PCONV
%
%   Url: http://ltfat.github.io/doc/reference/ref_dgt_pconv.html

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

  
L=size(f,1);

N=L/a;
b=L/M;

c=zeros(M,N);

for m=0:M-1
  work = pconv(f,involute(g).*expwave(L,m*b));
  c(m+1,:) = reshape(work(1:a:L),1,N);
end;

c=phaseunlock(c,a);


