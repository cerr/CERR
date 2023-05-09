function c=ref_dstii_1(f)
%-*- texinfo -*-
%@deftypefn {Function} ref_dstii_1
%@verbatim
%REF_DSTII  Reference Discrete Sine Transform type II
%   Usage:  c=ref_dstii(f);
%
%   The transform is computed by an FFT of 4 times the length of f.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_dstii_1.html}
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
  c=ref_dstii_1(real(f)) + i*ref_dstii_1(imag(f));
else
  lf=zeros(L*4,W);
  
  lf(2:2:2*L,:)=f;
  lf(2*L+2:2:end,:)=-flipud(f);

  fflong=imag(fft(lf));

  c=-fflong(2:L+1,:)/sqrt(2*L);
  
  % Scale last coefficients to obtain orthonormal transform.
  c(end,:)=1/sqrt(2)*c(end,:);
end


