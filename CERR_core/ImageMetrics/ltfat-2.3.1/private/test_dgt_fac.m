%-*- texinfo -*-
%@deftypefn {Function} test_dgt_fac
%@verbatim
%TEST_DGT  Test DGT full window backend
%
%  This script runs a throrough test of the COMP_DGT_FAC
%  and COMP_IDGT_FAC testing them on a range of input parameters.
%
%  Use TEST_WFAC first, to verify that COMP_WFAC and COMP_IWFAC
%  are working, since this tester depends on them.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_dgt_fac.html}
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

disp('--- Used subroutines ---');

which comp_wfac
which comp_iwfac
which comp_dgt_fac
which comp_idgt_fac


for ii=1:length(Lr);

  L=Lr(ii);
  
  M=Mr(ii);
  a=ar(ii);
  
  b=L/M;
  N=L/a;
  c=gcd(a,M);
  d=gcd(b,N);
  p=a/c;
  q=M/c;
  
  for W=1:3
    
    for R=1:3

      for rtype=1:2
	if rtype==1
	  rname='REAL ';	
	  f=tester_rand(L,W);
	  g=tester_rand(L,R);
	else
	  rname='CMPLX';	
	  f=tester_crand(L,W);
	  g=tester_crand(L,R);
	end;
	
	gf=comp_wfac(g,a,M);            
	cc=comp_dgt_fac(f,gf,a,M);  
	cc2=ref_dgt(f,g,a,M);
	
	res=norm(cc(:)-cc2(:));      
	
	failed='';
	if res>10e-10
	  failed='FAILED';
	  test_failed=test_failed+1;
	end;
      
	s=sprintf('DGT  %s L:%3i W:%2i R:%2i a:%3i b:%3i c:%3i d:%3i p:%3i q:%3i %0.5g %s',rname,L,W,R,a,b,c,d,p,q,res,failed);
	disp(s)
	
      end;


      for rtype=1:2
	if rtype==1
	  rname='REAL ';	
	  g=tester_rand(L,R);
	else
	  rname='CMPLX';	
	  g=tester_crand(L,R);
	end;

	cc=tester_crand(M,N*R*W);
	
	gf=comp_wfac(g,a,M);            
	f=comp_idgt_fac(ifft(cc)*sqrt(M),gf,L,a,M);
	f2=ref_idgt(reshape(cc,M*N*R,W),g,a,M);
	
	res=norm(f(:)-f2(:));      
	
	failed='';
	if res>10e-10
	  failed='FAILED';
	  test_failed=test_failed+1;
	end;
      
	s=sprintf('IDGT %s L:%3i W:%2i R:%2i a:%3i b:%3i c:%3i d:%3i p:%3i q:%3i %0.5g %s',rname,L,W,R,a,b,c,d,p,q,res,failed);
	disp(s)
	
      end;

    end;
    
  end;
  
end;

test_failed


