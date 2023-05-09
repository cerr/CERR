function test_failed=test_involute

Lr=[9,10];

test_failed=0;

disp(' ===============  TEST_INVOLUTE ===========');

for ii=1:length(Lr)
  
  L=Lr(ii);
  f=tester_crand(L,1);
  
  r1=conj(dft(f));
  r2=dft(involute(f));
  
  res=norm(r1-r2);
  [test_failed,fail]=ltfatdiditfail(res,test_failed);          
  s=sprintf('INVOLUTE  L:%3i %0.5g %s',L,res,fail);
  disp(s);

end;


%-*- texinfo -*-
%@deftypefn {Function} test_involute
%@verbatim
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_involute.html}
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

