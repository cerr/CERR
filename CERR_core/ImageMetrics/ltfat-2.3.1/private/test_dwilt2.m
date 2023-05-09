function test_failed=test_dwilt2

test_failed=0;
  
disp(' ===============  TEST_DWILT2 ================');

%-*- texinfo -*-
%@deftypefn {Function} test_dwilt2
%@verbatim
% Run some fixed test to test the interface.
% This is not a thourough tester.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_dwilt2.html}
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

% --- test 1 ----------------

L=64;
M=8;
Lf=63;
W=3;

f=tester_rand(Lf,Lf,W);

g=pgauss(L,1);
gd=wildual(g,M);

[c,Ls]=dwilt2(f,g,M);
r=idwilt2(c,gd,Ls);

res=r-f;

nres=norm(res(:));

[test_failed,fail]=ltfatdiditfail(nres,test_failed);
% failed='';
% if nres>10e-10
  % failed='FAILED';
  % test_failed=test_failed+1;
% end;

s=sprintf('DWILT2 Lf:%3i L:%3i %0.5g %s',Lf,L,nres,fail);
disp(s)


% --- test 2 -------------------
L=256;
M1=16;
M2=32;
W=1;

f=tester_rand(L,L,1);

g=pgauss(L,1);

gd1=wildual(g,M1);
gd2=wildual(g,M2);

c=dwilt2(f,g,[M1,M2]);
c2=ref_dwilt2(f,g,g,M1,M2);

rc=c-c2;
nres=norm(rc(:));
[test_failed,fail]=ltfatdiditfail(nres,test_failed);
% failed='';
% if nres>10e-10
  % failed='FAILED';
  % test_failed=test_failed+1;
% end;

s=sprintf('DWILT2 REF M1:%3i M2:%3i %0.5g %s',M1,M2,nres,fail);
disp(s)



r=idwilt2(c,gd1,gd2);

res=r-f;

nres=norm(res(:));
[test_failed,fail]=ltfatdiditfail(nres,test_failed);
% failed='';
% if nres>10e-10
  % failed='FAILED';
  % test_failed=test_failed+1;
% end;

s=sprintf('DWILT2 INV M1:%3i M2:%3i %0.5g %s',M1,M2,nres,fail);
disp(s)





