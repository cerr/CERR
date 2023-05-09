function [lat]=ref_lattice(V,L);
%-*- texinfo -*-
%@deftypefn {Function} ref_lattice
%@verbatim
%REF_LATTICE  List of lattice points.
%   Usage:  lat=ref_lattice(V,L)  
%
%   Returns the lattice given by av and bv.
%   The output format is a 2xMxN matrix, where
%   each column is a point on the lattice.
%
%   The lattice must be in lower triangular Hermite normal form.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_lattice.html}
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
  
a=V(1,1);
b=V(2,2);
s=V(2,1);
M=abs(L/b);
N=abs(L/a);

% Create lattice.
lattice=zeros(2,M*N);
for n=0:N-1
  for m=0:M-1
    soffset=mod(s*n,b);
    % Determine gridpoint in rectangular coordinates.
    %lat(:,m+n*M+1) = V(:,1)*n+V(:,2)*m;
    lat(1,m+n*M+1) = n*a;
    lat(2,m+n*M+1) = m*b+soffset;
  end;
end;

% Mod' the lattice.
lat=mod(lat,L);



