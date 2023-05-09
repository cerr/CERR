function test_failed=test_windrivers
%-*- texinfo -*-
%@deftypefn {Function} test_windrivers
%@verbatim
%TEST_WINDRIVERS  Test if the window drivers pass certain construction
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_windrivers.html}
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
  
    disp(' ===============  TEST_WINDRIVERS ================');
    
    
a=5;
M=6;
L=60;

% We expect that if the following commands finish, they produce the correct
% output, so we only test that they do not generate fatal errors.

g=gabwin('gauss',a,M,L);
g=gabwin({'gauss',1},a,M,L);
gd=gabwin('gaussdual',a,M,L);
gd=gabwin({'tight','gauss'},a,M,L);
g=gabwin({'dual',{'hann',M}},a,M,L);



