function test_failed=test_dwilt

which comp_dwilt
which comp_idwilt

Lr=[4, 6, 8,12,16,12,18,32,30];
Mr=[2, 3, 2, 3, 4, 2, 3, 4, 3];

disp(' ===============  TEST_DWILT ================');

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
          wtype='FIR';
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
	
	c=dwilt(f,g,M,L);  
      
	a=M;
	
	c2=ref_dwilt(f,g,a,M);
	r=idwilt(c,gd);  
	
	res=norm(c(:)-c2(:));
        [test_failed,fail]=ltfatdiditfail(res,test_failed);
	s=sprintf('REF  %s %s L:%3i W:%2i a:%3i M:%3i %0.5g %s',S,wtype,L,W,a,M,res,fail);
	disp(s)
	
	rdiff=f-r;
	res=norm(rdiff(:));
        [test_failed,fail]=ltfatdiditfail(res,test_failed);	
	s=sprintf('REC  %s %s L:%3i W:%2i a:%3i M:%3i %0.5g %s',S,wtype,L,W,a,M,res,fail);
	disp(s)

	g=wilorth(M,L);
        c=dwilt(f,g,M);  
        r=idwilt(c,g);
        rdiff=f-r;
        
	res=norm(rdiff(:));
        [test_failed,fail]=ltfatdiditfail(res,test_failed);	
	s=sprintf('ORTH %s %s L:%3i W:%2i a:%3i M:%3i %0.5g %s',S,wtype,L,W,a,M,res,fail);
	disp(s)

	c=dwilt(f,'gauss',M);
        r=idwilt(c,{'dual','gauss'});
	res=norm(f-r);
        [test_failed,fail]=ltfatdiditfail(res,test_failed);	
	s=sprintf('WIN %s %s L:%3i W:%2i a:%3i M:%3i %0.5g %s',S,wtype,L,W,a,M,res,fail);                
        disp(s)

        c=dwilt(f,{'tight','gauss'},M);
        r=idwilt(c,{'tight','gauss'});
	res=norm(f-r);
        [test_failed,fail]=ltfatdiditfail(res,test_failed);	
	s=sprintf('WIN TIGHT %s %s L:%3i W:%2i a:%3i M:%3i %0.5g %s',S,wtype,L,W,a,M,res,fail);
        disp(s)

      end;
    end;
  end;
end;













%-*- texinfo -*-
%@deftypefn {Function} test_dwilt
%@verbatim
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_dwilt.html}
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

