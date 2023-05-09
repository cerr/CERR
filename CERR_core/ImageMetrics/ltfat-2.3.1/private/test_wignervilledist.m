function test_failed = test_wignervilledist
Lr = [1, 19, 20];

test_failed = 0;

disp(' ===============  TEST_WIGERVILLEDIST ==============');

for ii = 1: length(Lr)
  L = Lr(ii);
    for n = 1:4
    
    if (n==1)
    type1 = 'auto';
    type2 = 'real';
    f = tester_rand(L,1);
    g = f;
    elseif (n==2)
    type1 = 'auto';
    type2 = 'complex';
    f = tester_crand(L,1);
    g = f;
    elseif (n==3)
    type1 = 'cross';
    type2 = 'real';
    f = tester_rand(L,1);
    g = tester_rand(L,1);
    elseif (n==4)
    type1 = 'cross';
    type2 = 'complex';
    f = tester_crand(L,1);
    g = tester_crand(L,1);
    end
  
    r1 = ref_wignervilledist(f,g);
    r2 = wignervilledist(f,g);
  
    res = norm(r1-r2);
  
    [test_failed, fail] = ltfatdiditfail(res, test_failed);
    s = sprintf('DWVD %3s %3s L:%3i %0.5g %s', type1, type2, L, res, fail);
    disp(s);
    end
end
end

%-*- texinfo -*-
%@deftypefn {Function} test_wignervilledist
%@verbatim
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_wignervilledist.html}
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

