function c=ref_rdft_1(f)
%-*- texinfo -*-
%@deftypefn {Function} ref_rdft_1
%@verbatim
%REF_RDFT_1  Reference RDFT by FFT
%   Usage:  c=ref_rdft_1(f);
%
%   Compute RDFT by doing a DFT and returning half the coefficients.
%
%   The transform is orthonormal
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_rdft_1.html}
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
Lhalf=ceil(L/2);
Lend=Lhalf*2-1;

if ~isreal(f)
  c=ref_rdft_1(real(f))+i*ref_rdft_1(imag(f));
else
  cc=fft(f);
  
  c=zeros(size(f));
  
  % Copy the first coefficient, it is real
  c(1,:)=1/sqrt(2)*real(cc(1,:));
  
  % Copy the cosine-part of the coefficients.
  c(2:2:Lend,:)=real(cc(2:Lhalf,:));
  
  % Copy the sine-part of the coefficients.
  c(3:2:Lend,:)=-imag(cc(2:Lhalf,:));
  
  % If f has an even length, we must also copy the Niquest-wave
  % (it is real)
  if mod(L,2)==0
    c(end,:)=1/sqrt(2)*real(cc(L/2+1,:));
  end;
  
  % Make it an ortonomal transform
  c=c/sqrt(L/2);
end;


