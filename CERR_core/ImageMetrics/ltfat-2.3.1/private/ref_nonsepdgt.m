function [c]=ref_nonsepdgt(f,g,a,M,lt)
%-*- texinfo -*-
%@deftypefn {Function} ref_nonsepdgt
%@verbatim
%REF_NONSEPDGT  Reference non-sep Discrete Gabor transform.
%   Usage:  c=ref_dgt(f,g,a,M,lt);
%
%   Linear algebra version of the algorithm. Create big matrix
%   containing all the basis functions and multiply with the transpose.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_nonsepdgt.html}
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

% Calculate the parameters that was not specified.
L=size(f,1);
g=fir2long(g,L);

b=L/M;
N=L/a;
W=size(f,2);
R=size(g,2);

% Create 2x2 grid matrix..
V=[a,0;...
   b/lt(2)*lt(1),b];
  
% Create lattice and Gabor matrix.
lat=ref_lattice(V,L);
G=ref_gaboratoms(g,lat);
  
% Apply matrix to f.
c=G'*f;

% reshape to correct output format.

c=reshape(c,M,N,R*W);



