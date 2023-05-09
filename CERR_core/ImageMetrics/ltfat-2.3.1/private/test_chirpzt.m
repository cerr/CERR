function test_failed=test_chirpzt
disp(' ===============  TEST_CHIRPZT ================');
test_failed=0;
%-*- texinfo -*-
%@deftypefn {Function} test_chirpzt
%@verbatim
% Goertzel algorithm has a bad precision for larger L.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_chirpzt.html}
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
global LTFAT_TEST_TYPE;
tolerance = 2e-10;
if strcmpi(LTFAT_TEST_TYPE,'single')
   tolerance = 8e-4;
end
L = 36;
W = 17;
f=tester_crand(L,W); 



res = norm(fft(cast(f,'double'))-chirpzt(f,L));
[test_failed,fail]=ltfatdiditfail(res,test_failed,tolerance);
fprintf('RES 1 cols: L:%3i, W:%3i %s\n',L,W,fail);

res = norm(fft(cast(f,'double'),[],2)-chirpzt(f,[],[],[],[],2));
[test_failed,fail]=ltfatdiditfail(res,test_failed,tolerance);
fprintf('RES 1 rows: L:%3i, W:%3i %s\n',L,W,fail);


 res = norm(fft(cast(f,'double'),2*L)-chirpzt(f,2*L,0.5/L));
 [test_failed,fail]=ltfatdiditfail(res,test_failed,tolerance);
 fprintf('RES 1/2 cols: L:%3i, W:%3i %s\n',L,W,fail);
 
 res = norm(fft(cast(f,'double'),5*L)-chirpzt(f,5*L,0.2/L));
 [test_failed,fail]=ltfatdiditfail(res,test_failed,tolerance);
 fprintf('RES 1/5 cols: L:%3i, W:%3i %s\n',L,W,fail);
 
 
 offset = 10;
 c = chirpzt(f,5*L-offset,0.2/L,offset*0.2/L);
 cfft = fft(cast(f,'double'),5*L);
 res = norm(cfft(offset+1:end,:)-c);
 [test_failed,fail]=ltfatdiditfail(res,test_failed,tolerance);
 fprintf('RES 1/5, offset, cols: L:%3i, W:%3i %s\n',L,W,fail);
 
 

