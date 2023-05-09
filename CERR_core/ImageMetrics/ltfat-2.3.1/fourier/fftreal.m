function f=fftreal(f,N,dim);
%-*- texinfo -*-
%@deftypefn {Function} fftreal
%@verbatim
%FFTREAL   FFT for real valued input data
%   Usage: f=fftreal(f);
%          f=fftreal(f,N,dim);
%
%   FFTREAL(f) computes the coefficients corresponding to the positive
%   frequencies of the FFT of the real valued input signal f.
%   
%   The function takes exactly the same arguments as fft. See the help on
%   fft for a thorough description.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/fourier/fftreal.html}
%@seealso{ifftreal, dft}
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

%   AUTHOR    : Peter L. Soendergaard
%   TESTING   : TEST_PUREFREQ
%   REFERENCE : OK
  
complainif_argnonotinrange(nargin,1,3,mfilename);

if nargin<3
  dim=[];  
end;

if nargin<2
  N=[];
end;

if ~isreal(f)
  error('Input signal must be real.');
end;


[f,N,Ls,W,dim,permutedsize,order]=assert_sigreshape_pre(f,N,dim,'FFTREAL');

if ~isempty(N)
   f=postpad(f,N);
end

N2=floor(N/2)+1;

f=comp_fftreal(f);

% Set the new size in the first dimension.
permutedsize(1)=N2;

f=assert_sigreshape_post(f,dim,permutedsize,order);


