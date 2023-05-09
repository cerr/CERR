function test_failed = test_fwt2

disp('========= TEST FWT2 ============');
global LTFAT_TEST_TYPE;
tolerance = 1e-8;
if strcmpi(LTFAT_TEST_TYPE,'single')
   tolerance = 1e-4;
end

test_failed = 0;

dims = { [20,30], [150,151],[226,253], };
flags = {'standard','tensor'};
filt = {{'mband1',2},{'db10',4},{'sym8',4},{'spline4:4',4},};


for ii=1:numel(dims)
   f = tester_rand(dims{ii});
   for jj=1:numel(flags)
      for ff=1:numel(filt)
         c = fwt2(f,filt{ff}{1},filt{ff}{2},flags{jj});
         fhat = ifwt2(c,filt{ff}{1},filt{ff}{2},dims{ii},flags{jj});
         err = norm(f-fhat,'fro');
         [test_failed,fail]=ltfatdiditfail(err,test_failed,tolerance);
         fprintf('J=%d, %5.5s, dim=[%3.d,%3.d], flag=%8.8s, err=%.4e %s\n',filt{ff}{2},filt{ff}{1},size(f,1),size(f,2),flags{jj},err,fail);
      end
   end
end

%-*- texinfo -*-
%@deftypefn {Function} test_fwt2
%@verbatim
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_fwt2.html}
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

