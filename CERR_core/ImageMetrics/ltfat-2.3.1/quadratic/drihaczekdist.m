function r = drihaczekdist(f)
%-*- texinfo -*-
%@deftypefn {Function} drihaczekdist
%@verbatim
%DRIHACZEKDIST discrete Rihaczek distribution
%   Usage r = drihaczekdist(f);
%
%
%   DRIHACZEKDIST(f) computes a discrete Rihaczek distribution of vector
%   f. The discrete Rihaczek distribution is computed by
%
%   where k, l=0,...,L-1 and c is the Fourier transform of f.
%
%   *WARNING**: The quadratic time-frequency distributions are highly 
%   redundant. For an input vector of length L, the quadratic time-frequency
%   distribution will be a L xL matrix. If f is multichannel 
%   (LxW matrix), the resulting distributions are stacked along
%   the third dimension such that the result is LxL xW cube.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/quadratic/drihaczekdist.html}
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

%   AUTHOR: Jordy van Velthoven
%   TESTING: TEST_DRIHACZEKDIST
%   REFERENCE: REF_DRIHACZEKDIST

complainif_notenoughargs(nargin, 1, 'DRIHACZEKDIST');

[f,Ls]=comp_sigreshape_pre(f,upper(mfilename));

c = dgt(f, f, 1, Ls);

r = dsft(c);

