function lambdas=comp_gfeigs(gf,L,a,M)
%-*- texinfo -*-
%@deftypefn {Function} comp_gfeigs
%@verbatim
%COMP_GFEIGS_SEP
%   Usage:  lambdas=comp_gfeigs(gf,a,M);
%
%   Compute Eigenvalues of a Gabor frame operator in
%   the separable case.
%
%   This is a computational routine, do not call it directly.
%
%   See help on GFBOUNDS
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_gfeigs.html}
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

LR=prod(size(gf));
R=LR/L;

b=L/M;
N=L/a;

c=gcd(a,M);
d=gcd(b,N);
p=b/d;
q=N/d;

% Initialize eigenvalues
AF=Inf;
BF=0;

% Holds subsubmatrix.
C=zeros(p,q*R,assert_classname(gf));

lambdas=zeros(p,c*d,assert_classname(gf));

% Iterate through all the subsubmatrices.
for k=0:c*d-1
  % Extract p x q*R matrix of array.
  C(:)=gf(:,k+1);
  
  % Get eigenvalues of 'squared' subsubmatrix.
  lambdas(:,1+k)=eig(C*C');
    
end;

% Clean eigenvalues, they are real, and
% scale them correctly.
lambdas=real(lambdas);

% Reshape and sort.
lambdas=sort(lambdas(:));










