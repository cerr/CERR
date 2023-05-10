function test_failed = test_libltfat_heap(varargin)
test_failed = 0;

fprintf(' ===============  %s ================ \n',upper(mfilename));

L = 1025;
f = rand(L,1);
fPtr = libpointer('doublePtr',f);
idxArr = randperm(L);

heap = calllib('libltfat','ltfat_heap_init_d', L, fPtr);

for w = idxArr
    calllib('libltfat','ltfat_heap_insert_d', heap, w-1);
end

sortedIdxArr = zeros(L,1);

for w = 1:L
    sortedIdxArr(w) = calllib('libltfat','ltfat_heap_delete_d', heap);
end

calllib('libltfat','ltfat_heap_done_d',heap);

res = norm(f(sortedIdxArr+1) - sort(f,'descend'));

plot([f,f(sortedIdxArr+1),sort(f,'descend')])

if res>0
    test_failed=1;
end





%plot(sort(f,'descend'))
%
%   Url: http://ltfat.github.io/doc/libltfat/modules/libltfat/testing/mUnit/test_libltfat_heap.html

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


