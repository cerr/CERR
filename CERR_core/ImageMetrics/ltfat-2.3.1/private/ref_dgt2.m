function c=ref_dgt2(f,g1,g2,a1,a2,M1,M2);
%-*- texinfo -*-
%@deftypefn {Function} ref_dgt2
%@verbatim
%REF_DGT2  Reference DGT2
%
%  Compute a DGT2 using a DGT along each dimension.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_dgt2.html}
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

L1=size(f,1);
L2=size(f,2);

N1=L1/a1;
N2=L2/a2;

c=dgt(f,g1,a1,M1);

c=reshape(c,M1*N1,L2);

c=c.';

c=dgt(c,g2,a2,M2);

c=reshape(c,M2*N2,M1*N1);

c=c.';

c=reshape(c,M1,N1,M2,N2);


