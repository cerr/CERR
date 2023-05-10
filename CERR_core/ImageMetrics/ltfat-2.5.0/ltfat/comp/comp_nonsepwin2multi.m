function mwin=comp_nonsepwin2multi(g,a,M,lt,L);
% Create multiwindow from non-sep win
%
%   Url: http://ltfat.github.io/doc/comp/comp_nonsepwin2multi.html

% Copyright (C) 2005-2022 Peter L. Soendergaard <peter@sonderport.dk> and others.
% This file is part of LTFAT version 2.5.0
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
  
g=fir2long(g,L);

Lg=size(g,1);

b=L/M;
mwin=zeros(Lg,lt(2),assert_classname(g));
l=long2fir((0:L-1).'/L,Lg);
for ii=0:lt(2)-1
  wavenum=mod(ii*lt(1),lt(2))*b/lt(2);
  mwin(:,ii+1)=exp(2*pi*i*l*wavenum).*circshift(g,ii*a);
end;

