function test_failed = test_libltfat_fftfftshift(varargin)
test_failed = 0;

fprintf(' ===============  %s ================ \n',upper(mfilename));

definput.flags.complexity={'double','single'};
[flags]=ltfatarghelper({},definput,varargin);
dataPtr = [flags.complexity, 'Ptr'];

Larr = [1,9,11,110,111];

for L = Larr

        z = cast((1:L)' + i*(L:-1:1)',flags.complexity);
        zi = complex2interleaved(fft(z));
        zout = randn(size(zi),flags.complexity);

        ziPtr = libpointer(dataPtr,zi);
        zoutPtr = libpointer(dataPtr,zout);

        trueres = fftshift(z);

        funname = makelibraryname('fftfftshift',flags.complexity,1);
        status = calllib('libltfat',funname,ziPtr,L,zoutPtr);

        res = norm(trueres - ifft(interleaved2complex(zoutPtr.Value)));


        [test_failed,fail]=ltfatdiditfail(res+status,test_failed);
        fprintf(['FFTFFTSHIFT OP L:%3i, %s %s %s\n'],L,flags.complexity,ltfatstatusstring(status),fail);

        status = calllib('libltfat', funname, ziPtr,L,ziPtr);

        res = norm(trueres - (ifft(interleaved2complex(ziPtr.Value))));

        [test_failed,fail]=ltfatdiditfail(res+status,test_failed);
        fprintf(['FFTFFTSHIFT IP L:%3i, %s %s %s\n'],L,flags.complexity,ltfatstatusstring(status),fail);      

        z = cast((1:L)',flags.complexity);
        zi = complex2interleaved(fftreal(z));
        zout = randn(size(zi),flags.complexity);

        ziPtr = libpointer(dataPtr,zi);
        zoutPtr = libpointer(dataPtr,zout);        
               
        funname = makelibraryname('fftrealfftshift',flags.complexity,1);
        status = calllib('libltfat',funname,ziPtr,L,zoutPtr);

        trueres = fftshift(z);
        res = norm(trueres - real(ifftreal(interleaved2complex(zoutPtr.Value),L)));

        [test_failed,fail]=ltfatdiditfail(res+status,test_failed);
        fprintf(['FFTREALFFTSHIFT OP L:%3i, %s %s %s\n'],L,flags.complexity,ltfatstatusstring(status),fail);

        status = calllib('libltfat', funname, ziPtr,L,ziPtr);

        res = norm(trueres - real(ifftreal(interleaved2complex(ziPtr.Value),L)));

        [test_failed,fail]=ltfatdiditfail(res+status,test_failed);
        fprintf(['FFTREALFFTSHIFT IP L:%3i, %s %s %s\n'],L,flags.complexity,ltfatstatusstring(status),fail);

end



%
%   Url: http://ltfat.github.io/doc/libltfat/modules/libltfat/testing/mUnit/test_libltfat_fftfftshift.html

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

