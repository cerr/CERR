function test_failed = test_dsft
Lr = [2, 19, 20];

test_failed = 0;

disp(' ===============  TEST_DSFT ==============');

for ii = 1: length(Lr)
  L = Lr(ii);
    for n = 1:4
    
    if (n == 1)
    type = 'real';
    L2 = L;
    F = tester_rand(L,L);
    elseif (n == 2)
    type = 'real';
    L2 = L+1;
    F = tester_rand(L,L2);
    elseif (n == 3)
    type = 'complex';
    L2 = L;
    F = tester_crand(L,L);
    else
    type = 'complex';
    L2 = L+1;
    F = tester_crand(L,L2); 
    end
    
    r1 = ref_dsft(F);
    r2 = dsft(F);
  
    res = norm(r1-r2);
  
    [test_failed, fail] = ltfatdiditfail(res, test_failed);
    s = sprintf('DSFT %3s size: %dx%d %0.5g %s', type, L, L2, res, fail);
    disp(s);
    end
end

%-*- texinfo -*-
%@deftypefn {Function} test_dsft
%@verbatim
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_dsft.html}
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

