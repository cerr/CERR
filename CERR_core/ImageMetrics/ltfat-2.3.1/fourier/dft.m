function f=dft(f,N,dim);
%-*- texinfo -*-
%@deftypefn {Function} dft
%@verbatim
%DFT   Normalized Discrete Fourier Transform
%   Usage: f=dft(f);
%          f=dft(f,N,dim);
%
%   DFT computes a normalized or unitary discrete Fourier transform. The 
%   unitary discrete Fourier transform is computed by
%   
%                          L-1
%     c(k+1) = 1/sqrt(L) * sum f(l+1)*exp(-2*pi*i*k*l/L)
%                          l=0
%
%   for k=0,...,L-1.
%
%   The output of DFT is a scaled version of the output from fft. The
%   function takes exactly the same arguments as fft. See the help on fft
%   for a thorough description.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/fourier/dft.html}
%@seealso{idft}
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

%   AUTHOR: Peter L. Soendergaard, Jordy van Velthoven
%   TESTING: TEST_DFT
%   REFERENCE: REF_DFT

complainif_argnonotinrange(nargin,1,3,mfilename);

if nargin<3
  dim=[];
end;

if nargin<2
  N=[];
end;

[f,N,Ls,W,dim,permutedsize,order]=assert_sigreshape_pre(f,N,dim,'DFT');

% Force FFT along dimension 1, since we have permuted the dimensions
% manually
f=fft(f,N,1)/sqrt(N);

f=assert_sigreshape_post(f,dim,permutedsize,order);


