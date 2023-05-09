function f=comp_inonsepdgtreal_quinqux(coef,g,a,M,do_timeinv)
%-*- texinfo -*-
%@deftypefn {Function} comp_inonsepdgtreal_quinqux
%@verbatim
%COMP_INONSEPDGTREAL_QUINQUX  Compute Inverse discrete Gabor transform
%   Usage:  f=inonsepdgt(c,g,a,M);
%
%   Input parameters:
%         c     : Array of coefficients.
%         g     : Window function.
%         a     : Length of time shift.
%         M     : Number of channels
%         do_timeinv : Do a time invariant phase ?
%   Output parameters:
%         f     : Signal.
%
%
%   This is a computational subroutine, do not call it directly.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_inonsepdgtreal_quinqux.html}
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

%   AUTHOR : Nicki Holighaus and Peter L. Soendergaard
%   TESTING: TEST_NONSEPDGT
%   REFERENCE: OK

% Check input paramameters.


M2=size(coef,1);
N=size(coef,2);
W=size(coef,3);
L=N*a;

coef2=zeros(M,N,W,assert_classname(coef,g));

coef2(1:M2,:,:)=coef;
if rem(M,2)==0
    coef2(M2+1:M,1:2:N-1,:)=conj(coef(M2-1:-1:2,1:2:N-1,:));
    coef2(M2:M,2:2:N  ,:)  =conj(coef(M2-1:-1:1,2:2:N,:));
else
    coef2(M2+1:M,1:2:N-1,:)=conj(coef(M2:-1:2,1:2:N-1,:));
    coef2(M2+1:M,2:2:N  ,:)=conj(coef(M2-1:-1:1,2:2:N,:));
end;

coef=coef2;

lt=[1 2];
mwin=comp_nonsepwin2multi(g,a,M,lt,L);

% phase factor correction (backwards), for more information see 
% analysis routine

E = exp(2*pi*i*a*kron(0:N/2-1,ones(1,2)).*...
        rem(kron(ones(1,N/2), 0:2-1),2)/M);

coef = bsxfun(@times,coef,E);

% simple algorithm: split into sublattices and add the result from eacg
% sublattice.
f=zeros(L,W,assert_classname(coef,g));
for ii=0:2-1
    % Extract sublattice
    sub=coef(:,ii+1:2:end,:);
    f=f+comp_idgt(sub,mwin(:,ii+1),2*a,[0 1],0,0);  
end;
    

