function test_failed=test_dgt_ola
%-*- texinfo -*-
%@deftypefn {Function} test_dgt_ola
%@verbatim
%TEST_DGT_OLA  Test DGT Overlap-add implementation
%
%  This script runs a throrough test of the DGT using the OLA algorithm,
%  testing it on a range of input parameters.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_dgt_ola.html}
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
      
Lr  = [48,420, 4, 8,240];
ar  = [ 2,  3, 2, 2,  4];
Mr  = [ 4,  4, 4, 4,  6];
glr = [ 8, 24, 4, 4, 12];
blr = [16, 60, 4, 4,120];

test_failed=0;

disp(' ===============  TEST_DGT_OLA ================');

disp('--- Used subroutines ---');

which comp_dgt_ola
which comp_dgtreal_ola

for ii=1:length(Lr);

  L=Lr(ii);
  
  M=Mr(ii);
  a=ar(ii);
  gl=glr(ii);
  bl=blr(ii);

  b=L/M;
  N=L/a;
  
  for W=1:3

    for rtype=1:2
      
      if rtype==1
        rname='REAL ';	
        f=randn(L,W);
        g=randn(gl,1);        

        c1 = comp_dgtreal_ola(f,g,a,M,bl);
        c2 = dgtreal(f,g,a,M);

      else
        rname='CMPLX';	
        f=tester_crand(L,W);
        g=tester_crand(gl,1);

        c1 = comp_dgt_ola(f,g,a,M,bl);
        c2 = dgt(f,g,a,M);

      end;
        
      res = c1-c2;
      res = norm(res(:));
      
      [test_failed,fail]=ltfatdiditfail(res,test_failed);
      s=sprintf('REF %s L:%3i W:%3i a:%3i M:%3i gl:%3i bl:%3i %0.5g %s',...
                rname,L,W,a,M,gl,bl,res,fail);
      disp(s)
      
    end;
  
  end;
  
end;
      



