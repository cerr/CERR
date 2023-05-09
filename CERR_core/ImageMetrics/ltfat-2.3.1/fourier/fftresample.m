function f=fftresample(f,L,dim)
%-*- texinfo -*-
%@deftypefn {Function} fftresample
%@verbatim
%FFTRESAMPLE   Resample signal using Fourier interpolation
%   Usage:  h=fftresample(f,L);
%           h=fftresample(f,L,dim);
%
%   FFTRESAMPLE(f,L) returns a Fourier interpolation of the signal f*
%   to length L. If the function is applied to a matrix, it will apply
%   to each column.  
%
%   FFTRESAMPLE(f,L,dim) does the same along dimension dim.
%
%   If the input signal is *not* a periodic signal (or close to), the
%   DCTRESAMPLE method gives much better results at the endpoints.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/fourier/fftresample.html}
%@seealso{dctresample, middlepad}
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

%   AUTHOR: Peter L. Soendergaard
  
% ------- Checking of input --------------------
complainif_argnonotinrange(nargin,2,3,mfilename);

if nargin<3
  dim=[];
end;

[f,L,Ls,W,dim,permutedsize,order]=assert_sigreshape_pre(f,L,dim,'FFTRESAMPLE');

wasreal=isreal(f);

% The 'dim=1' below have been added to avoid fft and middlepad being
% smart about choosing the dimension.
% In addition, postpad is explicitly told to pad with zeros.
if isreal(f)
  L2=floor(L/2)+1;
  f=ifftreal(postpad(fftreal(f,[],1),L2,0,1),L,1)/Ls*L;
else
  f=ifft(middlepad(fft(f,[],1),L,1))/Ls*L;
end;

f=assert_sigreshape_post(f,dim,permutedsize,order);


