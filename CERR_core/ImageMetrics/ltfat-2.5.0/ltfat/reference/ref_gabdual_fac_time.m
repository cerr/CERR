function ff=ref_gabdual_fac_time(gf,L,a,M)
%REF_GABDUAL_FAC_TIME  Computes factorization of canonical dual window 
%
%
%   Url: http://ltfat.github.io/doc/reference/ref_gabdual_fac_time.html

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

LR=prod(size(gf));
R=LR/L;

b=L/M;
N=L/a;

c=gcd(a,M);
d=gcd(b,N);
  
p=b/d;
q=N/d;

ff=zeros(p*q*R,c*d);

G=zeros(p,q*R);
for ii=1:c*d
  % This essentially computes pinv of each block.

  G(:)=gf(:,ii);
  S=G*G';
  Gpinv=(S\G);

  ff(:,ii)=Gpinv(:);
end;




