function f=dctresample(f,L,dim)
%-*- texinfo -*-
%@deftypefn {Function} dctresample
%@verbatim
%DCTRESAMPLE   Resample signal using Fourier interpolation
%   Usage:  h=dctresample(f,L);
%           h=dctresample(f,L,dim);
%
%   DCTRESAMPLE(f,L) returns a discrete cosine interpolation of the signal f*
%   to length L. If the function is applied to a matrix, it will apply
%   to each column.
%
%   DCTRESAMPLE(f,L,dim) does the same along dimension dim.
%
%   If the input signal is not a periodic signal (or close to), this method
%   will give much better results than FFTRESAMPLE at the endpoints, as
%   this method assumes than the signal is even a the endpoints.
%
%   The algorithm uses a DCT type iii.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/fourier/dctresample.html}
%@seealso{fftresample, middlepad, dctiii}
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

[f,L,Ls,W,dim,permutedsize,order]=assert_sigreshape_pre(f,L,dim,'DCTRESAMPLE');

wasreal=isreal(f);

% The 'dim=1' below have been added to avoid dct and middlepad being
% smart about choosing the dimension.
f=dctiii(postpad(dctii(f,[],1),L))*sqrt(L/Ls);

f=assert_sigreshape_post(f,dim,permutedsize,order);

if wasreal
  f=real(f);
end;


