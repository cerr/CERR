function test_failed=test_frametf
%-*- texinfo -*-
%@deftypefn {Function} test_frametf
%@verbatim
%TEST_FRAMETF  Test the frames tf-plane conversion
%
%   This tests if framecoef2tf and frametf2coef work.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_frametf.html}
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
L = 456;
W = 3;

f = tester_rand(L,W);

Fr{1}  = frame('dgt','gauss',10,20);
Fr{1}  = frame('dgtreal','gauss',10,20);
Fr{3}  = frame('dwilt','gauss',20);
Fr{4}  = frame('wmdct','gauss',20);

   gfilt={tester_rand(30,1),...
          tester_rand(20,1),...
          tester_rand(15,1),...
          tester_rand(10,1)};
      
Fr{5} = frame('ufilterbank',    gfilt,3,4);

Fr{6} = frame('ufwt','db4',4);

Fr{7} = frame('uwfbt',{'db4',4});

Fr{8} = frame('uwpfbt',{'db4',4});

for ii=1:numel(Fr)
  
  F=Fr{ii};
  
  % To avoid holes in Fr
  if isempty(F)
    continue;
  end;
  
  c = frana(F,f);
  ctf = framecoef2tf(F,c);
  
  c2 = frametf2coef(F,ctf);
  
  res = norm(c-c2);
  [test_failed,fail]=ltfatdiditfail(res,test_failed);
  fprintf('COEFEQ  %s  %0.5g %s\n',F.type,res,fail);
 
end

