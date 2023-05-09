function n=fftindex(N,nyquistzero)
%-*- texinfo -*-
%@deftypefn {Function} fftindex
%@verbatim
%FFTINDEX  Frequency index of FFT modulations
%   Usage: n=fftindex(N);
%
%   FFTINDEX(N) returns the index of the frequencies of the standard FFT of
%   length N as they are ordered in the output from the fft routine. The
%   numbers returned are in the range -ceil(N/2)+1:floor(N/2)
%
%   FFTINDEX(N,0) does as above, but sets the Nyquist frequency to zero.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/fourier/fftindex.html}
%@seealso{dft}
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
%   TESTING: OK
%   REFERENCE: OK

complainif_argnonotinrange(nargin,1,2,mfilename);

if nargin ==1
    if rem(N,2)==0
        n=[0:N/2,-N/2+1:-1].';
  else
      n=[0:(N-1)/2,-(N-1)/2:-1].';
  end;
else
    if rem(N,2)==0
        n=[0:N/2-1,0,-N/2+1:-1].';
  else
      n=[0:(N-1)/2,-(N-1)/2:-1].';
  end;
end;

