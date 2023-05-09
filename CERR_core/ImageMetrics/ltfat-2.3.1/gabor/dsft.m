function F=dsft(F);
%-*- texinfo -*-
%@deftypefn {Function} dsft
%@verbatim
%DSFT  Discrete Symplectic Fourier Transform
%   Usage:  C=dsft(F);
%
%   DSFT(F) computes the discrete symplectic Fourier transform of F.
%   F must be a matrix or a 3D array. If F is a 3D array, the 
%   transformation is applied along the first two dimensions.
%
%   Let F be a K xL matrix. Then the DSFT of F is given by
%
%                                L-1 K-1
%     C(m+1,n+1) = 1/sqrt(K*L) * sum sum F(k+1,l+1)*exp(2*pi*i(k*n/K-l*m/L))
%                                l=0 k=0
%
%   for m=0,...,L-1 and n=0,...,K-1.
%
%   The DSFT is its own inverse.
%
%   References:
%     H. G. Feichtinger, M. Hazewinkel, N. Kaiblinger, E. Matusiak, and
%     M. Neuhauser. Metaplectic operators on c^n. The Quarterly Journal of
%     Mathematics, 59(1):15--28, 2008.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/dsft.html}
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

%   AUTHOR : Peter L. Soendergaard, Jordy van Velthoven (TESTING).
%   TESTING: TEST_DSFT 
%   REFERENCE: REF_DSFT

complainif_argnonotinrange(nargin,1,1,mfilename);

D=ndims(F);

if (D<2) || (D>3)
  error('Input must be two/three dimensional.');
end;

W=size(F,3);

if W==1
  F=dft(idft(F).');
else
  % Apply to set of planes.
  
  R1=size(F,1);
  R2=size(F,2);
  Fo=zeros(R2,R1,W,assert_classname(F));
  for w=1:W
    Fo(:,:,w)=dft(idft(F(:,:,w).'));
  end;
  F=Fo;
end;


