function test_failed=test_pgauss
%-*- texinfo -*-
%@deftypefn {Function} test_pgauss
%@verbatim
%TEST_PGAUSS  Test PGAUSS
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_pgauss.html}
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
  
    disp(' ===============  TEST_PGAUSS ================');
    
    L=19;
    
    % Test that tfr=1 works
    res=norm(pgauss(L)-dft(pgauss(L)));
    [test_failed,fail]=ltfatdiditfail(res,test_failed);
    
    fprintf(['PGAUSS 1 %0.5g %s\n'],res,fail);
    
    % Test dilation property
    res=norm(pgauss(L,7)-dft(pgauss(L,1/7)));
    [test_failed,fail]=ltfatdiditfail(res,test_failed);
    
    fprintf(['PGAUSS 2 %0.5g %s\n'],res,fail);
    
    % Test norm
    res=norm(pgauss(L))-1;
    [test_failed,fail]=ltfatdiditfail(res,test_failed);
    
    fprintf(['PGAUSS 3 %0.5g %s\n'],res,fail);

    
    % Test that dft(freq shift) == time shift
    res=norm(dft(pgauss(L,'cf',5))-pgauss(L,'delay',5));
    [test_failed,fail]=ltfatdiditfail(res,test_failed);
    
    fprintf(['PGAUSS 3 %0.5g %s\n'],res,fail);

    


