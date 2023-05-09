%-*- texinfo -*-
%@deftypefn {Function} test_pherm
%@verbatim
% This script test the quality of the Hermite implementation.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_pherm.html}
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

% There seem to be some numerical problems for ii>66

L=200;
H=pherm(L,0:159,'fast','qr');


H1=H(:,1:4:end);
H2=H(:,2:4:end);
H3=H(:,3:4:end);
H4=H(:,4:4:end);

norm(H1'*H1)
norm(H2'*H2)
norm(H3'*H3)
norm(H4'*H4)

norm(H1'*H2)
norm(H1'*H3)
norm(H1'*H4)

norm(H2'*H3)
norm(H2'*H4)

norm(H3'*H4)

norm(abs(H./dft(H))-1)


