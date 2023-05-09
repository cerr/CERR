function test_failed=test_phaselock
%-*- texinfo -*-
%@deftypefn {Function} test_phaselock
%@verbatim
%TEST_PHASELOCK  Test phaselock and phaseunlock
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_phaselock.html}
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

disp(' ===============  TEST_PHASELOCK ================');

% set up parameters
L=420;
f=tester_rand(L,1);
g=pgauss(L);
a=10;b=30;M=L/b;

c = dgt(f,g,a,M);
cp1 = ref_phaselock(c,a);
cp2 = phaselock(c,a,'lt',[0 1]);

% compare original phaselock with mine for rectangular case
res=norm(cp1-cp2,'fro');
[test_failed,fail]=ltfatdiditfail(res,test_failed);
fprintf(['PHASELOCK REF RECT %0.5g %s\n'],res,fail);

% comparisons for non-separable case
c_big = dgt(f,g,a,2*M);
c_quin = dgt(f,g,a,M,'lt',[1 2]);

c_bigp = phaselock(c_big,a);
c_quinp= phaselock(c_quin,a,'lt',[1 2]);

% compare the quincunx lattice with twice transform on twice as many
% chanels
res=norm(c_bigp(1:2:end,1)-c_quinp(:,1),'fro');
[test_failed,fail]=ltfatdiditfail(res,test_failed);
fprintf(['PHASELOCK QUIN 1    %0.5g %s\n'],res,fail);

res=norm(c_bigp(2:2:end,2)-c_quinp(:,2),'fro');
[test_failed,fail]=ltfatdiditfail(res,test_failed);
fprintf(['PHASELOCK QUIN 2    %0.5g %s\n'],res,fail);

% testing of phaseunlock routine
res=norm(c_big - phaseunlock(c_bigp,a),'fro');
[test_failed,fail]=ltfatdiditfail(res,test_failed);
fprintf(['PHASEUNLOCK RECT    %0.5g %s\n'],res,fail);

res=norm(c_quin - phaseunlock(c_quinp,a,'lt',[1 2]),'fro');
[test_failed,fail]=ltfatdiditfail(res,test_failed);
fprintf(['PHASEUNLOCK QUIN    %0.5g %s\n'],res,fail);


cfi = dgtreal(f,g,a,M);
cti = dgtreal(f,g,a,M,'timeinv');

res=norm(cfi - phaseunlockreal(cti,a,M),'fro');
[test_failed,fail]=ltfatdiditfail(res,test_failed);
fprintf(['PHASEUNLOCKREAL     %0.5g %s\n'],res,fail);

res=norm(phaselockreal(cfi,a,M) - cti,'fro');
[test_failed,fail]=ltfatdiditfail(res,test_failed);
fprintf(['PHASELOCKREAL       %0.5g %s\n'],res,fail);

res=norm(cfi - phaseunlockreal(cti,a,M,'precise'),'fro');
[test_failed,fail]=ltfatdiditfail(res,test_failed);
fprintf(['PHASEUNLOCKREAL PREC %0.5g %s\n'],res,fail);

res=norm(phaselockreal(cfi,a,M,'precise') - cti,'fro');
[test_failed,fail]=ltfatdiditfail(res,test_failed);
fprintf(['PHASELOCKREAL PREC  %0.5g %s\n'],res,fail);
