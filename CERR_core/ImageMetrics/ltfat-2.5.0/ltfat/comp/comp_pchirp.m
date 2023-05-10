function g=comp_pchirp(L,n)
%COMP_PCHIRP  Compute periodic chirp
%   Usage:  g=comp_pchirp(L,n);
%
%   pchirp(L,n) returns a periodic, discrete chirp of length L that
%   revolves n times around the time-frequency plane in frequency. n must be
%   an integer number.
%
%   This is a computational routine. Do not call it unless you have
%   verified the input parameters.
%
%   Url: http://ltfat.github.io/doc/comp/comp_pchirp.html

% Copyright (C) 2005-2022 Peter L. Soendergaard <peter@sonderport.dk> and others.
% This file is part of LTFAT version 2.5.0
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

%   AUTHOR : Peter L. Søndergaard
%   TESTING: OK
%   REFERENCE: OK

l= (0:L-1).';
X = mod(mod(mod(n*l,2*L).*l,2*L)*(L+1),2*L);
g = exp(pi*1i*X/L);

