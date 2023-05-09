function test_failed=test_rangecompress
%-*- texinfo -*-
%@deftypefn {Function} test_rangecompress
%@verbatim
%TEST_RANGECOMPRESS Test range compression and expansion
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_rangecompress.html}
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

test_failed=0;

disp(' ===============  TEST_RANGECOMPRESS ================');

x=tester_crand(5,11);

y=rangecompress(x,'mulaw');
x_r=rangeexpand(y,'mulaw');

res=norm(x-x_r,'fro');

[test_failed,fail]=ltfatdiditfail(res,test_failed);
fprintf(['RANGECOMPRESS MULAW %0.5g %s\n'],res,fail);

y=rangecompress(x,'alaw');
x_r=rangeexpand(y,'alaw');

res=norm(x-x_r,'fro');

[test_failed,fail]=ltfatdiditfail(res,test_failed);
fprintf(['RANGECOMPRESS  ALAW %0.5g %s\n'],res,fail);



