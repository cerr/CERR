function c=ref_wmdct2(f,g1,g2,M1,M2);

L1=size(f,1);
L2=size(f,2);

c=wmdct(f,g1,M1);

c=reshape(c,L1,L2);

c=c.';

c=wmdct(c,g2,M2);

c=reshape(c,L2,L1);

c=c.';

c=reshape(c,M1,L1/M1,M2,L2/M2);


%-*- texinfo -*-
%@deftypefn {Function} ref_wmdct2
%@verbatim
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_wmdct2.html}
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

