function [test_failed,fail]=ltfatdiditfail(res,test_failed,tolerance);
%-*- texinfo -*-
%@deftypefn {Function} ltfatdiditfail
%@verbatim
%LTFATDIDITFAIL  Did a test fail
%
%  [test_fail,fail]=LTFATDIDITFAIL(res,test_fail) updates test_fail if
%  res is above threshhold and outputs the word FAIL in the variable
%  fail. Use only in testing scripts.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/ltfatdiditfail.html}
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
if nargin<3
  tolerance=1e-10;
  if strcmpi(LTFAT_TEST_TYPE,'single')
     tolerance=2e-4;
  end
end;
  
fail='';
if (abs(res)>tolerance) || isnan(res)
  fail='FAILED';
  test_failed=test_failed+1;
end;


