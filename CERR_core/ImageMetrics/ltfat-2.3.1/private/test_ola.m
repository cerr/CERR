
L=24;
Lg=4;

Lb=8;

f=randn(L,1);
g=randn(Lg,1);

ref1=pconv(f,postpad(g,L));
ola1=ref_pconv_ola_postpad(f,g,Lb);

norm(ref1-ola1)

ref2=pconv(f,fir2long(g,L));
ola2=ref_pconv_ola_fir2long(f,g,Lb);

norm(ref2-ola2)

[ref2,ola2,ref2-ola2]


%-*- texinfo -*-
%@deftypefn {Function} test_ola
%@verbatim
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_ola.html}
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

