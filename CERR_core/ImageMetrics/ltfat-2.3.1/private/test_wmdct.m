function test_failed=test_wmdct
%-*- texinfo -*-
%@deftypefn {Function} test_wmdct
%@verbatim
% Test the algorithm using LONG windows.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_wmdct.html}
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

which comp_dwiltiii
which comp_idwiltiii

disp(' ===============  TEST_WMDCT ================');

Lr=[4, 6, 8,12,16,12,18,32,30];
Mr=[2, 3, 2, 3, 4, 2, 3, 4, 3];

test_failed=0;

for ii=1:length(Lr);
  for W=1:3
    for ftype=1:2
      for wtype=1:2
	L=Lr(ii);
	M=Mr(ii);
	
	a=M;
      
	if wtype==1
	  % Full length window
	  g=pgauss(L);
	  gd=wildual(g,M);
          wtype='LONG';
	else
	  g=firwin('sqrthann',2*M,'2');
	  gd=g;
          wtype='FIR ';
	end;
	
	if ftype==1
	  % Complex-valued test case
	  f=tester_crand(L,W);
	  S='CMPLX';
	else
	  % Real-valued tes
	  f=tester_rand(L,W);
	  S='REAL ';
	end;
	
	c=wmdct(f,g,M,L);  
	
	a=M;
	
	c2=ref_dwiltiii(f,g,a,M);
	r=iwmdct(c,gd);  
	
	res=norm(c(:)-c2(:));
	
        [test_failed,fail]=ltfatdiditfail(res,test_failed);        
	s=sprintf('REF  %s %s L:%3i W:%2i a:%3i M:%3i %0.5g %s',S,wtype,L,W,a,M,res,fail);
	disp(s);
	
	rdiff=f-r;
	res=norm(rdiff(:));
	
        [test_failed,fail]=ltfatdiditfail(res,test_failed);
        
	s=sprintf('REC  %s %s L:%3i W:%2i a:%3i M:%3i %0.5g %s',S,wtype,L,W,a,M,res,fail);
	disp(s);
        
        g=wilorth(M,L);
        c=wmdct(f,g,M);  
        r=iwmdct(c,g);
        rdiff=f-r;
        
	res=norm(rdiff(:));
	
        [test_failed,fail]=ltfatdiditfail(res,test_failed);
	s=sprintf('ORTH %s %s L:%3i W:%2i a:%3i M:%3i %0.5g %s',S,wtype,L,W,a,M,res,fail);
	disp(s);

	
      end;
    end;
  end;
end;











