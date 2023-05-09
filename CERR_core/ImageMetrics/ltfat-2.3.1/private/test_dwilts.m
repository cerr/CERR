%-*- texinfo -*-
%@deftypefn {Function} test_dwilts
%@verbatim
% This is currently the tester for the
% new TF-transforms.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_dwilts.html}
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

Lr=[4, 6, 8, 12,16,12,18,32,30];
Mr=[2, 3, 2,  3, 4, 2, 3, 4, 3];

Wmax=2;

ref_funs={{'ref_dwilt','ref_dwilt_1'},...
	  {'ref_dwiltii','ref_dwiltii_1'},...
	  {'ref_dwiltiii','ref_dwiltiii_1'},...
	  {'ref_dwiltiv','ref_dwiltiv_1'},...
	  };

refinv_funs={{'ref_idwilt','ref_idwilt_1'},...
	     {'ref_idwiltii','ref_idwiltii_1'},...
	     {'ref_idwiltiii','ref_idwiltiii_1'},...
	     {'ref_idwiltiv','ref_idwiltiv_1'},...
	     };

inv_funs={{'ref_dwilt','ref_idwilt'},...
	  {'ref_dwiltii','ref_idwiltii'},...
	  {'ref_dwiltiii','ref_idwiltiii'},...
	  {'ref_dwiltiv','ref_idwiltiv'},...
	  };

% ---------- reference testing --------------------
% Test that the transforms agree on values.

for funpair=ref_funs
    
    for ii=1:length(Lr);
      
      for W=1:Wmax

	L=Lr(ii);
	
	M=Mr(ii);
	a=M;
	
	N=L/a;
    
	f=tester_rand(L,W);
	g=ref_win(funpair{1}{1},'test',L,a,M);
    
	c1=feval(funpair{1}{1},f,g,a,M);
	c2=feval(funpair{1}{2},f,g,a,M);
	
	res=norm(c1(:)-c2(:));

	if abs(res)>1e-10
	  fail='FAILED';
	else
	  fail='';
	end;
    
	s=sprintf('REF %10s L:%3i W:%2i a:%3i M:%3i %0.5g %s',funpair{1}{2},L,W,a,M,res,fail);
	disp(s)   	
      end;
      
    end;
end;

% ---------- reference inverse function testing ---------------
% Test that the transforms agree on values.

for funpair=refinv_funs
    
    for ii=1:length(Lr);
      
      for W=1:Wmax

	L=Lr(ii);
	
	M=Mr(ii);
	a=M;
	
	N=L/a;
    
	c=tester_rand(M*N,W);

	g=ref_win(funpair{1}{1},'test',L,a,M);
  
	f1=feval(funpair{1}{1},c,g,a,M);
	f2=feval(funpair{1}{2},c,g,a,M);
	
	res=norm(f1(:)-f2(:));

	if abs(res)>1e-10
	  fail='FAILED';
	else
	  fail='';
	end;
    
	s=sprintf('REF %10s L:%3i W:%2i a:%3i M:%3i %0.5g %s',funpair{1}{2},L,W,a,M,res,fail);
	disp(s)
	
      end;
      
    end;
end;

%------------ inversion testing -----------------
% Test that the transforms are invertible

for funpair=inv_funs
    
    for ii=1:length(Lr);
      
      for W=1:Wmax

	L=Lr(ii);
	
	M=Mr(ii);
	a=M;
	
	N=L/a;
    
	f=tester_rand(L,W);
	g=ref_win(funpair{1}{1},'test',L,a,M);
	gamma=ref_tgabdual(funpair{1}{1},g,L,a,M);
    
	c=feval(funpair{1}{1},f,g,a,M);
	fr=feval(funpair{1}{2},c,gamma,a,M);
	
	res=norm(f(:)-fr(:));

	[test_failed,fail]=ltfatdiditfail(nres,test_failed);
	if abs(res)>1e-10
	  fail='FAILED';
	else
	  fail='';
	end;
    
	s=sprintf('INV %10s L:%3i W:%2i a:%3i M:%3i %0.5g %s',funpair{1}{1},L,W,a,M,res,fail);
	disp(s)
      end;
      
    end;

end;





