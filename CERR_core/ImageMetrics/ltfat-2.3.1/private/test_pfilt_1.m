function test_failed=test_pfilt
%-*- texinfo -*-
%@deftypefn {Function} test_pfilt_1
%@verbatim
%
%
%   This is the old test_pfilt from before the struct filters was
%   introduced.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_pfilt_1.html}
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

Lr =[9,9,10,10,10,12];
Lgr=[9,4,10, 7,10,12];
ar =[3,3, 5, 5, 1, 3];

test_failed=0;

disp(' ===============  TEST_PFILT ==============');

disp('--- Used subroutines ---');

which comp_pfilt

for jj=1:length(Lr)
  L=Lr(jj);
  Lg=Lgr(jj);
  a=ar(jj);
  
  for W=1:3
  
    for rtype=1:2
      if rtype==1
        rname='REAL ';	
        f=tester_rand(L,W);
        g=tester_rand(Lg,1);
      else
        rname='CMPLX';	
        f=tester_crand(L,W);
        g=tester_crand(Lg,1);
      end;
                 
      h1=pfilt(f,g,a);
      h2=ref_pfilt(f,g,a);
      
      res=norm(h1-h2);
      [test_failed,fail]=ltfatdiditfail(res,test_failed);        
      s=sprintf('PFILT %3s  L:%3i W:%3i Lg:%3i a:%3i %0.5g %s',rname,L,W,Lg,a,res,fail);
      disp(s);
    end;
  end;
end;



