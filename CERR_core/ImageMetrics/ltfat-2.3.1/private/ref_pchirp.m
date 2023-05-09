function g=ref_pchirp(L,n)
%-*- texinfo -*-
%@deftypefn {Function} ref_pchirp
%@verbatim
%PCHIRP  Periodic chirp
%   Usage:  g=pchirp(L,n);
%
%   pchirp(L,n) returns a periodic, discrete chirp of length L that
%   revolves n times around the time-frequency plane in frequency. n must be
%   an integer number.
%
%   To get a chirp that revolves around the time-frequency plane in time,
%   use :
%
%     dft(pchirp(L,N));  
%
%   The chirp is computed by:
%   
%       g(l+1) = exp(pi*i*n*(l-ceil(L/2))^2*(L+1)/L) for l=0,...,L-1
%
%   The chirp has absolute value 1 everywhere. To get a chirp with unit
%   l^2-norm, divide the chirp by sqrt L.
%
%   Examples:
%   ---------
%
%   A spectrogram on a linear scale of an even length chirp:
%
%     sgram(pchirp(40,2),'lin');
%
%   The DFT of the same chirp, now revolving around in time:
%
%     sgram(dft(pchirp(40,2)),'lin');
%
%   An odd-length chirp. Notice that the chirp starts at a frequency between
%   two sampling points:
%
%     sgram(pchirp(41,2),'lin');
%   
%
%   References:
%     H. G. Feichtinger, M. Hazewinkel, N. Kaiblinger, E. Matusiak, and
%     M. Neuhauser. Metaplectic operators on c^n. The Quarterly Journal of
%     Mathematics, 59(1):15--28, 2008.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_pchirp.html}
%@seealso{dft, expwave}
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

complainif_argnonotinrange(nargin,2,2,mfilename);

% Compute normalized chirp

% Old code, has low numerical precision and do not work correctly for odd legths.
%g=(exp((0:L-1).^2/L*pi*i*n)/sqrt(L)).';

% Compute normalized chirp
m = (0:L-1).';
%X = mod(n*(m-ceil(L/2)).^2*(L+1),2*L);
X = mod(n*m.^2*(L+1),2*L);
g = exp(pi*1i*X/L);

