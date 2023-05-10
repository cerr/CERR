function f=ref_idgt(c,g,a,M)
%REF_DGT  Reference Inverse Discrete Gabor transform.
%   Usage:  c=ref_idgt(f,g,a,M);
%
%   Linear algebra version of the algorithm. Create big matrix
%   containing all the basis functions and multiply with the transpose.
%
%   Url: http://ltfat.github.io/doc/reference/ref_idgt.html

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

% Calculate the parameters that was not specified.
L=size(g,1);

b=L/M;
N=L/a;
W=size(c,2);

% Create 2x2 grid matrix..
V=[a,0;
   0,b];
  
% Create lattice and Gabor matrix.
lat=ref_lattice(V,L);
G=ref_gaboratoms(g,lat);
  
% Apply matrix to c.
f=G*c;



