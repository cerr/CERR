function f=shah(L,a);
%-*- texinfo -*-
%@deftypefn {Function} shah
%@verbatim
%SHAH  Discrete Shah-distribution
%   Usage: f=shah(L,a);
% 
%   SHAH(L,a) computes the discrete, normalized Shah-distribution of
%   length L with a distance of a between the spikes.
%
%   The Shah distribution is defined by 
%
%      f(n*a+1)=1/sqrt(L/a) 
%
%   for integer n, otherwise f is zero.
% 
%   This is also known as an impulse train or as the comb function, because
%   the shape of the function resembles a comb. It is the sum of unit
%   impulses ('diracs') with the distance a.
% 
%   If a divides L, then the DFT of SHAH(L,a) is SHAH(L,L/a).
% 
%   The Shah function has an extremely bad time-frequency localization.
%   It does not generate a Gabor frame for any L and a.
%
%   Examples:
%   ---------
%
%   A simple spectrogram of the Shah function (includes the negative
%   frequencies to display the whole TF-plane):
%
%     sgram(shah(256,16),'dynrange',80,'nf')
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/fourier/shah.html}
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

if nargin~=2
  error('Wrong number of input parameters.');
end;

%if mod(L,a)~=0
%  error('a must divide L.');
%end;

f=zeros(L,1);

f(1:a:L)=1/sqrt(L/a);


