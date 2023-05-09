function test_failed=test_signals;
%-*- texinfo -*-
%@deftypefn {Function} test_signals
%@verbatim
%TEST_SIGNALS
%
%  The script ensures that all files are correctly included by loading
%  the singals and checking their sizes.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_signals.html}
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
  
disp(' ===============  TEST_SIGNALS ===========');

test_failed=0;
  
[test_failed,fail]=ltfatdiditfail(numel(bat)-400,test_failed);
disp(['SIGNALS BAT       ',fail]);

[test_failed,fail]=ltfatdiditfail(numel(batmask)-1600,test_failed);
disp(['SIGNALS BATMASK   ',fail]);

[test_failed,fail]=ltfatdiditfail(numel(greasy)-5880,test_failed);
disp(['SIGNALS GREASY    ',fail]);

[test_failed,fail]=ltfatdiditfail(numel(linus)-41461,test_failed);
disp(['SIGNALS LINUS     ',fail]);

[test_failed,fail]=ltfatdiditfail(numel(gspi)-262144,test_failed);
disp(['SIGNALS GSPI      ',fail]);

[test_failed,fail]=ltfatdiditfail(numel(traindoppler)-157058,test_failed);
disp(['SIGNALS TRAINDOPPLER',fail]);

[test_failed,fail]=ltfatdiditfail(numel(otoclick)-2210,test_failed);
disp(['SIGNALS OTOCLICK  ',fail]);

[test_failed,fail]=ltfatdiditfail(numel(cameraman)-65536,test_failed);
disp(['SIGNALS CAMERAMAN ',fail]);

[test_failed,fail]=ltfatdiditfail(numel(cocktailparty)-363200,test_failed);
disp(['SIGNALS COCKTAILPARTY ',fail]);

[test_failed,fail]=ltfatdiditfail(numel(lichtenstein)-262144*3,test_failed);
disp(['SIGNALS LICHTENSTEIN ',fail]);


