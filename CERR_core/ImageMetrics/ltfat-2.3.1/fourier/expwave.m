function h=expwave(L,m,cent);
%-*- texinfo -*-
%@deftypefn {Function} expwave
%@verbatim
%EXPWAVE   Complex exponential wave
%   Usage:  h=expwave(L,m);
%           h=expwave(L,m,cent);
%
%   EXPWAVE(L,m) returns an exponential wave revolving m times around the
%   origin. The collection of all waves with wave number m=0,...,L-1
%   forms the basis of the discrete Fourier transform.
%
%   The wave has absolute value 1 everywhere. To get an exponential wave
%   with unit l^2-norm, divide the wave by sqrt(L). This is the
%   normalization used in the DFT function.
%
%   EXPWAVE(L,m,cent) makes it possible to shift the sampling points by
%   the amount cent. Default is cent=0.
%  
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/fourier/expwave.html}
%@seealso{dft, pchirp}
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

complainif_argnonotinrange(nargin,2,3,mfilename);

if nargin==2
  cent=0;
end;

h = exp(2*pi*i*((0:L-1)+cent)/L*m).';


