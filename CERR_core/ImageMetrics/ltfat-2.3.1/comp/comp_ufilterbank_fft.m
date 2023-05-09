function c=comp_ufilterbank_fft(f,g,a);  
%-*- texinfo -*-
%@deftypefn {Function} comp_ufilterbank_fft
%@verbatim
%COMP_UFILTERBANK_FFT   Classic filtering by FFT
%   Usage:  c=comp_ufilterbank_fft(f,g,a);
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_ufilterbank_fft.html}
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
M=size(g,2);

N=L/a;

c=zeros(N,M,W,assert_classname(f,g));

% This routine does not yet use FFTREAL, because it must be able to
% handle downsampling, which is much easier to express in the FFT case.
G=fft(fir2long(g,L));

for w=1:W
  F=fft(f(:,w));
  for m=1:M
    c(:,m,w)=ifft(sum(reshape(F.*G(:,m),N,a),2))/a;
  end;
end;

if isreal(f) && isreal(g)
  c=real(c);
end;
  


