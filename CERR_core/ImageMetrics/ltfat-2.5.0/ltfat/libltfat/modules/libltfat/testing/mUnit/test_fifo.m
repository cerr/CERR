function test_libltfat_fifo
gl = 20;
fifoLen = 120; % Must be at least as big as gl + max expected bufLen
M = gl;
a = 7;
g = firwin('hann',gl);
gd = gabdual(g,a,M);
gg = fftshift(g.*gd)*M;

fifoPtr = calllib('libltfat','rtdgtreal_fifo_init_d',fifoLen,gl,a,1);
fifoPtr.Value.buf.setdatatype('doublePtr',fifoLen+1)
ififoPtr = calllib('libltfat','rtidgtreal_fifo_init_d',fifoLen,gl,a,1);
ififoPtr.Value.buf.setdatatype('doublePtr',fifoLen+gl+1)

bufIn = (1:1000)';
%bufIn = ones(1,1000);
%
%   Url: http://ltfat.github.io/doc/libltfat/modules/libltfat/testing/mUnit/test_fifo.html

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
bufOut = zeros(size(bufIn));
bufLen = 100;
bufOutPtr = libpointer('doublePtr',zeros(gl,1));

for ii=1:length(bufIn)/bufLen
slice = (ii-1)*bufLen + 1 : ii*bufLen;
buf = bufIn(slice);
bufInPtr = libpointer('doublePtr',buf);
bufInPtrTmp = libpointer('doublePtr',zeros(size(buf)));

written = calllib('libltfat','rtdgtreal_fifo_write_d',fifoPtr,bufLen,bufInPtr);

while calllib('libltfat','rtdgtreal_fifo_read_d',fifoPtr,bufOutPtr) > 0
    bufOutPtr.Value = bufOutPtr.Value.*gg;
    written = calllib('libltfat','rtidgtreal_fifo_write_d',ififoPtr,bufOutPtr)
end

read = calllib('libltfat','rtidgtreal_fifo_read_d',ififoPtr,bufLen,bufInPtrTmp)

bufOut(slice) = bufInPtrTmp.Value;

end

inshift = circshift(bufIn,(gl-1));
inshift(1:(gl-1)) = 0;
stem([bufOut, inshift]);shg;




calllib('libltfat','rtdgtreal_fifo_done_d',fifoPtr);
calllib('libltfat','rtidgtreal_fifo_done_d',ififoPtr);



 
