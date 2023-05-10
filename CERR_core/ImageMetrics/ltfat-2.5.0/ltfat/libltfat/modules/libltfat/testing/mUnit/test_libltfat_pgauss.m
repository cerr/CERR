function test_failed = test_libltfat_pgauss(varargin)
test_failed = 0;

fprintf(' ===============  %s ================ \n',upper(mfilename));

definput.flags.complexity={'double','single'};
[flags]=ltfatarghelper({},definput,varargin);
dataPtr = [flags.complexity, 'Ptr'];

Larr =     [1 ,9,  11, 110,   1,    9,  11, 110];
tfratarr = [1, 2, 0.1, 100,   1,    2, 0.1, 100];
ctarr =    [0, 0,   0,   0, 0.1, -0.1, 1.0, 0.2]; 
cfarr =    [0, 0.1, 0,   0,-0.1,    0,   1,   0];    


for L = Larr
    for tfrId = 1:numel(tfratarr)
        tfr = tfratarr(tfrId);
        ct  = ctarr(tfrId);
        cf  = cfarr(tfrId);
        
        z = cast((1:L)',flags.complexity);
        zi = z;
        ziPtr = libpointer(dataPtr,zi);

        trueres = pgauss(L,tfr,'delay',-ct);

        status = calllib('libltfat',makelibraryname('pgauss',flags.complexity,0),...
            L,tfr,ct,ziPtr);

        res = norm(trueres - ziPtr.Value);

        [test_failed,fail]=ltfatdiditfail(res+status,test_failed);
        fprintf(['PGAUSS       L:%3i, tfr:%3.3f c_t:%3.3f %s %s %s\n'],L,tfr,ct,flags.complexity,ltfatstatusstring(status),fail);

        
        z = cast((1:L)'+1i*(L:-1:1)',flags.complexity);
        zi = complex2interleaved(z);
        ziPtr = libpointer(dataPtr,zi);

        trueres = pgauss(L,tfr,'delay',-ct,'cf',cf);

        status = calllib('libltfat',makelibraryname('pgauss',flags.complexity,1),...
            L,tfr,ct,cf,ziPtr);

        res = norm(trueres - interleaved2complex(ziPtr.Value));

        [test_failed,fail]=ltfatdiditfail(res+status,test_failed);
        fprintf(['PGAUSS CMPLX L:%3i, tfr:%3.3f c_t:%3.3f c_f:%3.3f %s %s %s\n'],L,tfr,ct,cf,flags.complexity,ltfatstatusstring(status),fail);

    end
end



%
%   Url: http://ltfat.github.io/doc/libltfat/modules/libltfat/testing/mUnit/test_libltfat_pgauss.html

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

