%-*- texinfo -*-
%@deftypefn {Function} test_wfac
%@verbatim
%TEST_WFAC  Test COMP_WFAC
%
%  This script runs a test of only the comp_wfac and comp_iwfac procedures.
%
%  The script TEST_DGT will test the complete DGT implementation.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_wfac.html}
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

test_failed=0;

which comp_wfac
which comp_iwfac
  
for ii=1:length(Lr);
  
  for R=1:3
    
    L=Lr(ii);
    
    M=Mr(ii);
    a=ar(ii);
    
    b=L/M;
    N=L/a;
    c=gcd(a,M);
    d=gcd(b,N);
    p=a/c;
    q=M/c;
    
    g=tester_crand(L,R);
    
    gf1=comp_wfac(g,a,M);
    gf2=ref_wfac(g,a,M);
    
    cdiff=gf1-gf2;
    res=norm(cdiff(:));      
    
    if res>10e-10
      disp('FAILED WFAC');
      test_failed=test_failed+1;
    end;
    
    s=sprintf('WFAC  L:%3i R:%2i a:%3i b:%3i c:%3i d:%3i p:%3i q:%3i %0.5g',L,R,a,b,c,d,p,q,res);
    disp(s)
    
    
    gf=tester_crand(p*q*R,c*d);
    
    g1=comp_iwfac(gf,L,a,M);
    g2=ref_iwfac(gf,L,a,M);
    
    cdiff=g1-g2;
    res=norm(cdiff(:));      
    
    if res>10e-10
      disp('FAILED IWFAC');
      test_failed=test_failed+1;
    end;
    
    s=sprintf('IWFAC L:%3i R:%2i a:%3i b:%3i c:%3i d:%3i p:%3i q:%3i %0.5g',L,R,a,b,c,d,p,q,res);
    disp(s)
    
  end;
  
end;

test_failed


