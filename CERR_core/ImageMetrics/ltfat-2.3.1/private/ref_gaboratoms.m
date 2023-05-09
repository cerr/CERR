function G=ref_gaboratoms(g,spoints);
%-*- texinfo -*-
%@deftypefn {Function} ref_gaboratoms
%@verbatim
%REF_GABORATOMS  Create Gabor transformation matrix
%   Usage:  G=ref_gaboratoms(g,spoints);
%
%   Given a set a TF-sampling points, as returned
%   by REF_GABORLATTICE, returns the corresponding
%   Gabor matrix. Each column of the output matriorx is
%   a Gabor atom.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_gaboratoms.html}
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

L=size(g,1);
W=size(g,2);
MN=size(spoints,2);

% Create Gabor matrix.
G=zeros(L,MN*W);
jj=(0:L-1).';

% Calculate atoms from sampling points.
for w=0:W-1
  for p=1:MN;
    G(:,p+w*MN)=exp(2*pi*i*spoints(2,p)*jj/L).*circshift(g(:,w+1),spoints(1,p));
  end;
end;





