function f=ifftreal(c,N,dim);
%-*- texinfo -*-
%@deftypefn {Function} ifftreal
%@verbatim
%IFFTREAL  Inverse FFT for real valued signals
%   Usage: f=ifftreal(c,N);
%          f=ifftreal(c,N,dim);
%
%   IFFTREAL(c,N) computes an inverse FFT of the positive frequency
%   Fourier coefficients c. The length N must always be specified,
%   because the correct transform length cannot be determined from the
%   size of c.
%
%   IFFTREAL(c,N,dim) does the same along dimension dim.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/fourier/ifftreal.html}
%@seealso{fftreal}
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

complainif_argnonotinrange(nargin,2,3,mfilename);

if nargin==2
  dim=[];  
end;

N2=floor(N/2)+1;

[c,~,~,~,dim,permutedsize,order]=assert_sigreshape_pre(c,N2,dim,'IFFTREAL');

% Clean for safety
c(1,:)=real(c(1,:));

f=comp_ifftreal(c,N);

% Restore the full size in the first dimension.
permutedsize(1)=N;

f=assert_sigreshape_post(f,dim,permutedsize,order);

