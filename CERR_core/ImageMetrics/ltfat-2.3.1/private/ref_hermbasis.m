function [V]=ref_hermbasis(L)
%-*- texinfo -*-
%@deftypefn {Function} ref_hermbasis
%@verbatim
%REF_HERMBASIS  Orthonormal basis of discrete Hermite functions.
%   Usage:  V=hermbasis(L);
%
%   HERMBASIS(L) will compute an orthonormal basis of discrete Hermite
%   functions of length L. The vectors are returned as columns in the
%   output.
%
%   All the vectors in the output are eigenvectors of the discrete Fourier
%   transform, and resemble samplings of the continuous Hermite functions
%   to some degree.
%
%
%   References:
%     H. M. Ozaktas, Z. Zalevsky, and M. A. Kutay. The Fractional Fourier
%     Transform. John Wiley and Sons, 2001.
%     
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_hermbasis.html}
%@seealso{dft, pherm}
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
%   TESTING: TEST_HERMBASIS
%   REFERENCE: OK

% Create tridiagonal sparse matrix
A=ones(L,3);
A(:,2)=(2*cos((0:L-1)*2*pi/L)-4).';
H=spdiags(A,-1:1,L,L);

H(1,L)=1;
H(L,1)=1;

H=H*pi/(i*2*pi)^2;

% Blow it to a full matrix, and use the linear algebra
% implementation. This always works.

[V,D]=eig(full(H));

% If L is not a factor of 4, then all the eigenvalues of the tridiagonal
% matrix are distinct. If L IS a factor of 4, then one eigenvalue has
% multiplicity 2, and we must split the eigenspace belonging to this
% eigenvalue into a an even and an odd subspace.
if mod(L,4)==0
  x=V(:,L/2);
  x_e=(x+involute(x))/2;
  x_o=(x-involute(x))/2;

  x_e=x_e/norm(x_e);
  x_o=x_o/norm(x_o);

  V(:,L/2)=x_o;
  V(:,L/2+1)=x_e;

end;



