function test_failed = test_libltfat_fftcircshift(varargin)
test_failed = 0;

fprintf(' ===============  %s ================ \n',upper(mfilename));

definput.flags.complexity={'double','single'};
[flags]=ltfatarghelper({},definput,varargin);
dataPtr = [flags.complexity, 'Ptr'];

Larr = [1,9,11,110,111];
shiftarr = [-10, 100, 0, -1, 1, 3, 52];

for L = Larr
    for shift = shiftarr

        z = cast((1:L)' + 1i*(L:-1:1)',flags.complexity);
        zi = complex2interleaved(fft(z));
        zout = randn(size(zi),flags.complexity);

        ziPtr = libpointer(dataPtr,zi);
        zoutPtr = libpointer(dataPtr,zout);

        trueres = circshift(z,shift);

        status = calllib('libltfat',makelibraryname('fftcircshift',flags.complexity,1),...
            ziPtr,L,shift,zoutPtr);

        res = norm(trueres - ifft(interleaved2complex(zoutPtr.Value)));


        [test_failed,fail]=ltfatdiditfail(res+status,test_failed);
        fprintf(['FFTCIRCSHIFT OP L:%3i, shift:%3i %s %s %s\n'],L,shift,flags.complexity,ltfatstatusstring(status),fail);

        status = calllib('libltfat',makelibraryname('fftcircshift',flags.complexity,1),...
            ziPtr,L,shift,ziPtr);

        res = norm(trueres - ifft(interleaved2complex(ziPtr.Value)));


        [test_failed,fail]=ltfatdiditfail(res+status,test_failed);
        fprintf(['FFTCIRCSHIFT IP L:%3i, shift:%3i %s %s %s\n'],L,shift,flags.complexity,ltfatstatusstring(status),fail);
        
        
        z = cast((1:L)',flags.complexity);
        zi = complex2interleaved(fftreal(z));
        zout = randn(size(zi),flags.complexity);

        ziPtr = libpointer(dataPtr,zi);
        zoutPtr = libpointer(dataPtr,zout);

        trueres = circshift(z,shift);

        status = calllib('libltfat',makelibraryname('fftrealcircshift',flags.complexity,1),...
            ziPtr,L,shift,zoutPtr);

        res = norm(trueres - real(ifftreal(interleaved2complex(zoutPtr.Value),L)));

        [test_failed,fail]=ltfatdiditfail(res+status,test_failed);
        fprintf(['FFTREALCIRCSHIFT OP L:%3i, shift:%3i %s %s %s\n'],L,shift,flags.complexity,ltfatstatusstring(status),fail);

        status = calllib('libltfat',makelibraryname('fftrealcircshift',flags.complexity,1),...
            ziPtr,L,shift,ziPtr);

        res = norm(trueres - real(ifftreal(interleaved2complex(ziPtr.Value),L)));


        [test_failed,fail]=ltfatdiditfail(res+status,test_failed);
        fprintf(['FFTREALCIRCSHIFT IP L:%3i, shift:%3i %s %s %s\n'],L,shift,flags.complexity,ltfatstatusstring(status),fail);
    end
end



%
%   Url: http://ltfat.github.io/doc/libltfat/modules/libltfat/testing/mUnit/test_libltfat_fftcircshift.html

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

