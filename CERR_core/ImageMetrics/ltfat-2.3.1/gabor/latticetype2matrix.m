function V=latticetype2matrix(L,a,M,lt);
%-*- texinfo -*-
%@deftypefn {Function} latticetype2matrix
%@verbatim
%LATTICETYPE2MATRIX  Convert lattice description to matrix form
%   Usage: V=latticetype2matrix(L,a,M,lt);
%
%   V=LATTICETYPE2MATRIX(L,a,M,lt) converts a standard description of a
%   lattice using the a, M and lt parameters into a 2x2
%   integer matrix description. The conversion is only valid for the
%   specified transform length L.
%
%   The output will be in lower triangular Hemite normal form.
%
%   For more information, see
%   http://en.wikipedia.org/wiki/Hermite_normal_form.
%
%   An example:
%
%     V = latticetype2matrix(120,10,12,[1 2])
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/latticetype2matrix.html}
%@seealso{matrix2latticetype}
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

L2=dgtlength(L,a,M,lt);

if L~=L2
    error('%s: Invalid transform length.',upper(mfilename));
end;

b=L/M;
s=b/lt(2)*lt(1);
V=[a 0;...
   s b];


