function test_failed = test_wfilt()
%-*- texinfo -*-
%@deftypefn {Function} test_wfilt
%@verbatim
% This function tests if tilters provided by wfilt_*
% functions indeed admit a perfect reconstruction
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_wfilt.html}
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
test_failed = 0;

w = {
    'algmband1'
    'algmband2'
    'cmband2'
    'cmband3'
    'cmband4'
    'cmband5'
    'cmband6'
    'coif1'
    'coif2'
    'coif3'
    'coif4'
    'coif5'
    'db1'
    'db2'
    'db3'
    'db4'
    'db5'
    'db6'
    'db7'
    'db8'
    'db9'
    'db10'
    'db11'
    'db12'
    'db13'
    'db14'
    'db15'
    'db16'
    'db17'
    'db18'
    'db19'
    'db20'
    'dden1'
    'dden2'
    'dden3'
    'dden4'
    'dden5'
    'dden6'
    'dgrid1'
    'dgrid2'
    'dgrid3'
    'hden1'
    'hden2'
    'hden3'
    'hden4'
    'lemarie10'
    'lemarie20'
    'lemarie30'
    'lemarie40'
    'mband1'
    'remez10:1:0.1'
    'remez20:1:0.1'
    'remez40:2:0.1'
    'spline1:1'
    'spline2:2'
    'spline3:3'
    'spline4:4'
    'spline5:5'
    'spline6:6'
    'spline7:7'
    'spline8:8'
    'spline1:3'
    'spline1:5'
    'spline1:7'
    'spline1:9'
    'spline3:1'
    'spline5:1'
    'spline7:1'
    'spline9:1'
    'spline2:4'
    'spline2:6'
    'spline2:8'
    'spline4:2'
    'spline6:2'
    'spline8:2'
    'spline3:5'
    'spline3:7'
    'spline3:9'
    'spline5:3'
    'spline7:3'
    'spline9:3'
    'spline4:6'
    'spline4:8'
    'spline6:4'
    'spline8:4'
    'spline5:7'
    'spline5:9'
    'spline7:5'
    'spline9:5'
    'spline6:8'
    'spline8:6'
    'spline7:9'
    'spline9:7'
    'sym1'
    'sym2'
    'sym3'
    'sym4'
    'sym5'
    'sym6'
    'sym7'
    'sym8'
    'sym9'
    'sym10'
    'sym11'
    'sym12'
    'sym13'
    'sym14'
    'sym15'
    'symdden1'
    'symdden2'
    'symds1'
    'symds2'
    'symds3'
    'symds4'
    'symds5'
    'symorth1'
    'symorth2'
    'symorth3'
    'symtight1'
    'symtight2'
    'oddevena1'
    'oddevenb1'
    'qshifta1'
    'qshifta2'
    'qshifta3'
    'qshifta4'
    'qshifta5'
    'qshifta6'
    'qshifta7'
    'qshiftb1'
    'qshiftb2'
    'qshiftb3'
    'qshiftb4'
    'qshiftb5'
    'qshiftb6'
    'qshiftb7'
    'optsyma1'
    'optsyma2'
    'optsyma3'
    'optsymb1'
    'optsymb2'
    'optsymb3'
    'ddena1'
    'ddena2'
    'ddenb1'
    'ddenb2'
     };


globtol = 5e-8;
disp('--------------TEST_WFIL-------------------');


exttype = {'per','odd','even','zero'};

L = 128;
f = tester_crand(L,1);
f = f/norm(f);


for wfilt = w'
for ext = exttype
    
   fhat = ifwt(fwt(f,wfilt{1},1,ext{1}),wfilt{1},1,L,ext{1});
   res = norm(f-fhat);
   [test_failed,fail]=ltfatdiditfail(res,test_failed,globtol);
   fprintf('%s ext:%s %0.5g %s\n',wfilt{1},ext{1},res,fail);
    
    
end
end

