function gammaf=comp_gabmixdual_fac(gf1,gf2,L,a,M)
%-*- texinfo -*-
%@deftypefn {Function} comp_gabmixdual_fac
%@verbatim
%COMP_GABMIXDUAL_FAC  Computes factorization of mix-dual.
%   Usage:  gammaf=comp_gabmixdual_fac(gf1,gf2,a,M)
%
%   Input parameters:
%      gf1    : Factorization of first window
%      gf2    : Factorization of second window
%      L      : Length of window.
%      a      : Length of time shift.
%      M      : Number of channels.
%
%   Output parameters:
%      gammaf : Factorization of mix-dual
%
%   GAMMAF is a factorization of a dual window of gf1
%
%   This function does not verify input parameters, call
%   GABMIXDUAL instead
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_gabmixdual_fac.html}
%@seealso{gabmixdual, comp_fac, compute_ifac}
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

%   AUTHOR : Peter L. Soendergaard.
%   TESTING: OK
%   REFERENCE: OK

LR=prod(size(gf1));
R=LR/L;

b=L/M;
N=L/a;

c=gcd(a,M);
d=gcd(b,N);
  
p=b/d;
q=N/d;

gammaf=zeros(p*q*R,c*d,assert_classname(gf1,gf2));

G1=zeros(p,q*R,assert_classname(gf1,gf2));
G2=zeros(p,q*R,assert_classname(gf1,gf2));
for ii=1:c*d

  G1(:)=gf1(:,ii);
  G2(:)=gf2(:,ii);
  S=G2*G1';
  Gpinv=M*S\G2;

  gammaf(:,ii)=Gpinv(:);
end;



