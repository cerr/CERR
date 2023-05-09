%-*- texinfo -*-
%@deftypefn {Function} test_gabimagepars
%@verbatim
%TEST_GABIMAGEPARS
%
%   This will run a simple test of the gabimagepars routine over a range
%   of sizes, and make a plot of the efficiancy in the end.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_gabimagepars.html}
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

x=800;
y=1200;

Ntests=10000;
res=zeros(Ntests,5);
offset=99;
for ii=1:Ntests;  
  Ls=ii+offset;    
  [res(ii,1),res(ii,2),res(ii,3),res(ii,4),res(ii,5)]=gabimagepars(Ls,x,y);  
end;

figure(1);
% res(:,3) is L
plot(res(:,3)./((1+offset:Ntests+offset)'))


