function test_failed = test_libltfat_maxtree(varargin)
test_failed = 0;

fprintf(' ===============  %s ================ \n',upper(mfilename));

definput.flags.complexity={'double','single'};
[flags]=ltfatarghelper({},definput,varargin);
dataPtr = [flags.complexity, 'Ptr'];

Larr =    [100,101,500,501,1025];
darr =    0;

for repeat = 1:1
  for depth = darr
    
for Lidx = 1:numel(Larr)
    
    L = Larr(Lidx);

    
    f = cast(randn(L,1)',flags.complexity);

    fPtr = libpointer(dataPtr,f);
    
    funname = makelibraryname('maxtree_initwitharray',flags.complexity,0);
    
    p = libpointer();
    
    calllib('libltfat',funname,L,depth,fPtr,p);
    
    maxPtr = libpointer(dataPtr,5);
    maxposPtr = libpointer('int64Ptr',cast(5,'int64'));
    
    
    funname = makelibraryname('maxtree_findmax',flags.complexity,0);
    status=calllib('libltfat',funname,p,maxPtr,maxposPtr);
    
    fprintf('max=%.3f, maxPos=%d\n',maxPtr.value, maxposPtr.value);
    
    fPtr.value(1) = 1000;
    
    funname = makelibraryname('maxtree_setdirty',flags.complexity,0);
    status=calllib('libltfat',funname,p,0,1);
    
    funname = makelibraryname('maxtree_findmax',flags.complexity,0);
    status=calllib('libltfat',funname,p,maxPtr,maxposPtr);
    
    fprintf('max=%.3f, maxPos=%d\n',maxPtr.value, maxposPtr.value);
    
    
    [fmax,fIdx] = max(fPtr.value);
    
    fprintf('max=%.3f, maxPos=%d\n', fmax, fIdx -1);
    fprintf('max=%.3f, maxPos=%d\n',maxPtr.value, maxposPtr.value);
    
    [test_failed,fail]=ltfatdiditfail(maxPtr.value-fmax + maxposPtr.value - (fIdx -1) ,test_failed,0);
    fprintf(['MAXTREE L:%3i, %s %s %s\n'],L,flags.complexity,ltfatstatusstring(status),fail);
    
    funname = makelibraryname('maxtree_done',flags.complexity,0);
    calllib('libltfat',funname,p);

end
  end
end



%
%   Url: http://ltfat.github.io/doc/libltfat/modules/libltfat/testing/mUnit/oldtest_libltfat_maxtree.html

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

