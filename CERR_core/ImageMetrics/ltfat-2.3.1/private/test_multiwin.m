function test_failed=test_multiwin
%-*- texinfo -*-
%@deftypefn {Function} test_multiwin
%@verbatim
%TEST_MULTIWIN  Test multiwindow gabdual and gabtight
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_multiwin.html}
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

      
Lr=[24,16,144,108,144,24,135,35,77,20];
ar=[ 4, 4,  9,  9, 12, 6,  9, 5, 7, 1];
Mr=[ 6, 8, 16, 12, 24, 8,  9, 7,11,20];
  
disp(' ===============  TEST_MULTIWIN ================');

disp('--- Used subroutines ---');

which comp_wfac
which comp_iwfac
which comp_gabdual_long
which comp_gabtight_long

test_failed=0;

for ii=1:length(Lr);

  L=Lr(ii);
  
  M=Mr(ii);
  a=ar(ii);
  
  r=zeros(L,1);

  for R=1:3
    
    for wintype = 1:2
      switch wintype
       case 1
        g=randn(L,R);
        rname='REAL ';
       case 2
        g=tester_crand(L,R);
        rname='CMPLX';
      end;
      
      N=L/a;

      % ----------- test canonical dual ----------------
      
      gd=gabdual(g,a,M);
      
      f=tester_crand(L,1);
      r=zeros(L,1);
      for ii=1:R
        c=dgt(f,g(:,ii),a,M);
        r=r+idgt(c,gd(:,ii),a);
      end;
      
      res=norm(f-r);
      [test_failed,fail]=ltfatdiditfail(res,test_failed);
      fprintf(['MULTIDUAL  %s L:%3i R:%3i a:%3i M:%3i %0.5g %s\n'],rname,L, ...
              R,a,M,res,fail);
      
      % ----------- test canonical tight ----------------
      
      gt=gabtight(g,a,M);
      
      f=tester_crand(L,1);
      r=zeros(L,1);
      for ii=1:R
        c=dgt(f,gt(:,ii),a,M);
        r=r+idgt(c,gt(:,ii),a);
      end;
      
      res=norm(f-r);
      [test_failed,fail]=ltfatdiditfail(res,test_failed);
      fprintf(['MULTITIGHT %s L:%3i R:%3i a:%3i M:%3i %0.5g %s\n'],rname,L, ...
              R,a,M,res,fail);
      
      % ----------- test frame bounds ----------------
      
      B=gabframebounds(gt,a,M);
      res=B-1;
      
      [test_failed,fail]=ltfatdiditfail(res,test_failed);
      fprintf(['MULTIFB    %s L:%3i R:%3i a:%3i M:%3i %0.5g %s\n'],rname,L, ...
              R,a,M,res,fail);
      
    end;
  end;
end;

