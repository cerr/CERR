function test_libltfat_gabframediag
[~,~,enuminfo]=libltfatprotofile;
LTFAT_FIRWIN = enuminfo.LTFAT_FIRWIN;

a = 14;
gl = 34;
M = 64;
g = zeros(gl,1);
d = zeros(a,1);
gPtr = libpointer('doublePtr',g);
dPtr = libpointer('doublePtr',d);

calllib('libltfat','ltfat_firwin_d',LTFAT_FIRWIN.LTFAT_HANN,gl,gPtr);


calllib('libltfat','ltfat_gabframediag_d',gPtr,gl,a,M,a,dPtr);


d =gabframediag(gPtr.Value,a,M,lcm(a,M));
d(1:a)-dPtr.Value




%
%   Url: http://ltfat.github.io/doc/libltfat/modules/libltfat/testing/mUnit/test_gabframediag.html

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

