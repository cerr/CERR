function [test_failed]=ltfatchecktest(res,outstr,test_failed,mode,tolerance);
%-*- texinfo -*-
%@deftypefn {Function} ltfatchecktest
%@verbatim
%LTFATCHECKTEST  Did a test fail, new method
%
%  [test_fail,fail]=LTFATCHECKTEST(res,test_fail) updates test_fail if
%  res is above threshhold and outputs the word FAIL in the variable
%  fail. Use only in testing scripts.
%
%  mode = 0 prints all results
%
%  mode = 1 is quiet mode to spot failures
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/ltfatchecktest.html}
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

if nargin<5
  tolerance=1e-10;
end;
  
fail=0;
if (abs(res)>tolerance) || isnan(res)
  fail=1;
end;

if (mode==0) || (fail==1)
    if (fail==1)
        outstr=[outstr,' FAILED'];
    end;
    disp(outstr);
end;

test_failed=test_failed+fail;


