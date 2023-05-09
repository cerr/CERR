function test_failed=test_gabmuleigs
%-*- texinfo -*-
%@deftypefn {Function} test_gabmuleigs
%@verbatim
%TEST_GABMULEIGS  Test GABMULEIGS
%
%   Test GABMULEIGS by comparing the output from the iterative and full algorithm.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_gabmuleigs.html}
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

disp(' ===============  TEST_GABMULEIGS ================');

test_failed=0;
  
a=20;
M=30;

L=a*M;
N=L/a;

c=randn(M,N);

g=gabtight(a,M,L);

% [V1,D1]=gabmuleigs(10,c,g,a,'iter');
% [V2,D2]=gabmuleigs(10,c,g,a,'full');
F = frame('dgt',g,a,M);
c = framenative2coef(F,c);
[V1,D1]=framemuleigs(F,F,c,10,'iter');
[V2,D2]=framemuleigs(F,F,c,10,'full');

res=norm(D1-D2);

[test_failed,fail]=ltfatdiditfail(res,test_failed);
s=sprintf('GABMULEIGS   L:%3i a:%3i M:%3i %0.5g %s',L,a,M,res,fail);
disp(s);





