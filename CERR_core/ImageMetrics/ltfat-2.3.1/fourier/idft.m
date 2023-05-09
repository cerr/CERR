function f=idft(c,N,dim)
%-*- texinfo -*-
%@deftypefn {Function} idft
%@verbatim
%IDFT  Inverse normalized Discrete Fourier Transform
%   Usage: f=idft(c);
%          f=idft(c,N,dim);
%
%   IDFT computes a normalized or unitary inverse discrete Fourier transform. 
%   The unitary discrete Fourier transform is computed by
%   
%                          L-1
%     f(l+1) = 1/sqrt(L) * sum c(k+1)*exp(2*pi*i*k*l/L)
%                          k=0
%
%   for l=0,...,L-1.
%
%   The output of IDFT is a scaled version of the output from ifft. The
%   function takes exactly the same arguments as ifft. See the help on ifft
%   for a thorough description.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/fourier/idft.html}
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

%   AUTHOR: Peter L. Soendergaard, Jordy van Velthoven
%   TESTING: TEST_IDFT
%   REFERENCE: TEST_DFT

complainif_argnonotinrange(nargin,1,3,mfilename);

if nargin<3
  dim=[];  
end;

if nargin<2
  N=[];
end;

[c,N,Ls,W,dim,permutedsize,order]=assert_sigreshape_pre(c,N,dim,'IDFT');

% Force IFFT along dimension 1, since we have permuted the dimensions
% manually
f=ifft(c,N,1)*sqrt(N);

f=assert_sigreshape_post(f,dim,permutedsize,order);


