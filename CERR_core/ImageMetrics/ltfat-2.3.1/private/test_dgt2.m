function test_failed=test_dgt2

test_failed=0;
  
disp(' ===============  TEST_DGT2 ================');

%-*- texinfo -*-
%@deftypefn {Function} test_dgt2
%@verbatim
% Run some fixed test to test the interface.
% This is not a thourough tester.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_dgt2.html}
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

% --- first test

a=6;
M=8;

Lf=71;
L=72;
W=3;

f=tester_rand(Lf,Lf,W);

g=pgauss(L,a*M/L);
gd=gabdual(g,a,M);

[c,Ls]=dgt2(f,g,a,M);
r=idgt2(c,gd,a,Ls);

res=f-r;
nres=norm(res(:));

[test_failed,fail]=ltfatdiditfail(nres,test_failed);
%failed='';
%if nres>10e-10
%  failed='FAILED';
%  test_failed=test_failed+1;
%end;

s=sprintf('DGT2 Lf:%3i L:%3i %0.5g %s',Lf,L,nres,fail);
disp(s)


% --- second test

a1=6;
M1=8;

a2=5;
M2=10;

L1=a1*M1;
L2=a2*M2;

W=1;

f=tester_rand(L1,L2,W);

g1=pgauss(L1,a1*M1/L1);
g2=pgauss(L2,a2*M2/L2);

gd1=gabdual(g1,a1,M1);
gd2=gabdual(g2,a2,M2);

c=dgt2(f,g1,g2,[a1,a2],[M1,M2]);
c2=ref_dgt2(f,g1,g2,a1,a2,M1,M2);

rc=c-c2;
nres=norm(rc(:));

[test_failed,fail]=ltfatdiditfail(nres,test_failed);
%failed='';
%if nres>10e-10
%  failed='FAILED';
%  test_failed=test_failed+1;
%end;

s=sprintf('DGT2 REF L1:%3i L2:%3i %0.5g %s',L1,L2,nres,fail);
disp(s)


r=idgt2(c,gd1,gd2,[a1,a2]);

res=r-f;

nres=norm(res(:));

[test_failed,fail]=ltfatdiditfail(nres,test_failed);
%failed='';
%if nres>10e-10
%  failed='FAILED';
%  test_failed=test_failed+1;
%end;

s=sprintf('DGT2 INV L1:%3i L2:%3i %0.5g %s',L1,L2,nres,fail);
disp(s)



