function [c]=ref_dgtns(f,gamma,V)
%-*- texinfo -*-
%@deftypefn {Function} ref_dgtns
%@verbatim
%REF_DGT  Reference Discrete Gabor transform for non-separable lattices.
%   Usage:  c=ref_dgtns(f,gamma,V);
%
%   Linear algebra version of the algorithm. Create big matrix
%   containing all the basis functions and multiply with the transfpose.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_dgtns.html}
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
L=size(gamma,1);

% Create lattice and Gabor matrix.
lat=ref_lattice(V,L);
G=ref_gaboratoms(gamma,lat);
  
% Apply matrix to f.
c=G'*f;



