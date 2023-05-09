function test_extended_ltfat()
%-*- texinfo -*-
%@deftypefn {Function} test_extended_ltfat
%@verbatim
% This test suite runs extended tests which either:
%   
%    Take long time to finish
%   
%    Their failure can only be checked by inspecting plots
%
%    We do not care whether they work with single precision or not.
%
%    Any that should be run at least before doing the release
%    but do not fit to be included in test_all_ltfat
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_extended_ltfat.html}
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

tests_todo = {
    'erbfilters',...
    'fbreassign',...
    'fbwarped_framebounds',...
    'wfilt',...
    'argfirwin',...
    'gabphasederiv',...
    'audfilters',...
    'demos'
};

total_tests_failed=0;
list_of_failed_tests={};

for name = tests_todo
       tmpfailed = feval(['test_',name{1}]);
       if tmpfailed>0
           list_of_failed_tests{end+1} = ['test_',name{1}];
           total_tests_failed = total_tests_failed + tmpfailed;
       end
       
end



