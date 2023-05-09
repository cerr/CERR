function test_failed=test_frft



disp(' ===============  TEST_FRFT ===========');

Lr=[9,10,11,12];

test_failed=0;

%-*- texinfo -*-
%@deftypefn {Function} test_frft
%@verbatim
% Test the hermite functions and discrete frft
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_frft.html}
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
for ii=1:length(Lr)
	L=Lr(ii);
	F=fft(eye(L))/sqrt(L);

	% check if hermite functions are eigenfunctions of F
	V=hermbasis(L,4);
	res=norm(abs(F*V)-abs(V));
	[test_failed,fail]=ltfatdiditfail(res,test_failed);          
        s=fprintf('HERMBASIS L:%3i %0.5g %s\n',L,res,fail);

	% Frft of order 1 becomes ordinary DFT
	f1=tester_crand(L,1);
	f2=tester_crand(1,L);

	p=4;
	frf1=dfracft(f1,1,[],p);
	frf2=dfracft(f2,1,2,p);
	res=norm(F*f1-frf1);
	[test_failed,fail]=ltfatdiditfail(res,test_failed);          
        s=fprintf('DFRACFT  L:%3i, %0.5g %s\n',L,res,fail);
	res=norm(f2*F-frf2);
	[test_failed,fail]=ltfatdiditfail(res,test_failed);          
        s=fprintf('DFRACFT  L:%3i, %0.5g %s\n',L,res,fail);

	frf1=dfracft(f1,1);
	frf2=dfracft(f2,1,2);
	res=norm(F*f1-frf1);
	[test_failed,fail]=ltfatdiditfail(res,test_failed);          
        s=fprintf('DFRACFT  L:%3i %0.5g %s\n',L,res,fail);
	res=norm(f2*F-frf2);
	[test_failed,fail]=ltfatdiditfail(res,test_failed);          
        s=fprintf('DFRACFT  L:%3i %0.5g %s\n',L,res,fail);


end


