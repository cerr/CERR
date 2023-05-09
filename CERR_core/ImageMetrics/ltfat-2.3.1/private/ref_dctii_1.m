function c=ref_dctii_1(f)
%-*- texinfo -*-
%@deftypefn {Function} ref_dctii_1
%@verbatim
%REF_DCTII  Reference Discrete Consine Transform type II
%   Usage:  c=ref_dctii(f);
%
%   The transform is computed by an FFT of 4 times the length of f.
%   See the Wikipedia article on "Discrete Cosine Transform"
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_dctii_1.html}
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
W=size(f,2);

if ~isreal(f)
  c=ref_dctii_1(real(f))+i*ref_dctii_1(imag(f));
else
  lf=zeros(L*4,W);
  
  lf(2:2:2*L,:)=f;
  lf(2*L+2:2:end,:)=flipud(f);

  fflong=real(fft(lf));

  c=fflong(1:L,:)/sqrt(2*L);
  
  % Scale first coefficients to obtain orthonormal transform.
  c(1,:)=1/sqrt(2)*c(1,:);
end;


