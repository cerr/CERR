function test_failed=test_demos
%-*- texinfo -*-
%@deftypefn {Function} test_demos
%@verbatim
%TEST_DEMOS  Test if all the demos runs without errors.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_demos.html}
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
  
  test_failed=0;
  
  s=dir([ltfatbasepath,filesep,'demos',filesep,'demo_*.m']);

  for ii=1:numel(s)
     filename = s(ii).name;
     
     disp(filename);
     
     % The demo is run in separate function to avoid 
     % variable name clash
     rundemo(filename(1:end-2));
     
     
  end;
  
  
function rundemo(demoname)
   close all;
   eval(demoname);


