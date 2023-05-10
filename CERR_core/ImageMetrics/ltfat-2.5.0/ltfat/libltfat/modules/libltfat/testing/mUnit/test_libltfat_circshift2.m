function test_failed = test_libltfat_circshift2(varargin)
test_failed = 0;

fprintf(' ===============  %s ================ \n',upper(mfilename));

definput.flags.complexity={'double','single'};
[flags]=ltfatarghelper({},definput,varargin);
dataPtr = [flags.complexity, 'Ptr'];

Larr = [9,11,110];
Larr2 = [8,13,118];
shiftarr = [-10, 100, 0, -1, 1, 3];
shiftarr2 = [-5, 10, 0, -11, 1, 33];

for do_complex = 0:1
    complexstring = '';
    if do_complex, complexstring = 'complex'; end
    for lidx = 1:numel(Larr)
        L = Larr(lidx)*Larr2(lidx);
        for sidx = 1:numel(shiftarr)
            shift = [shiftarr(sidx), shiftarr2(sidx)];
            
            if do_complex
                z = cast((1:L)'+1i*(L:-1:1)',flags.complexity);
                zi = complex2interleaved(z);
                zout = randn(size(zi),flags.complexity);
                
                ziPtr = libpointer(dataPtr,zi);
                zoutPtr = libpointer(dataPtr,zout);
            else
                z = cast((1:L)',flags.complexity);
                zi = z;
                zout = randn(size(zi),flags.complexity);
                
                ziPtr = libpointer(dataPtr,zi);
                zoutPtr = libpointer(dataPtr,zout);
            end
            
            trueres = circshift(reshape(z,Larr(lidx),Larr2(lidx)),shift);
            
            
            status = calllib('libltfat',makelibraryname('circshift2',flags.complexity,do_complex),...
                ziPtr,Larr(lidx),Larr2(lidx),shiftarr(sidx), shiftarr2(sidx),zoutPtr);
            
            if do_complex
                res = norm(trueres - reshape(interleaved2complex(zoutPtr.Value),Larr(lidx),Larr2(lidx)));
            else
                res = norm(trueres - reshape(zoutPtr.Value,Larr(lidx),Larr2(lidx)));
            end
            
            [test_failed,fail]=ltfatdiditfail(res+status,test_failed,0);
            fprintf(['CIRCSHIFT2 OP L:[%3i,%3i], shift:[%3i,%3i] %s %s %s %s\n'],Larr(lidx),Larr2(lidx),shift(1),shift(2),flags.complexity,complexstring,ltfatstatusstring(status),fail);
            
            status = calllib('libltfat',makelibraryname('circshift2',flags.complexity,do_complex),...
                ziPtr,Larr(lidx),Larr2(lidx),shiftarr(sidx), shiftarr2(sidx),ziPtr);
            
            if do_complex
                res = norm(trueres - reshape(interleaved2complex(zoutPtr.Value),Larr(lidx),Larr2(lidx)));
            else
                res = norm(trueres - reshape(zoutPtr.Value,Larr(lidx),Larr2(lidx)));
            end
            
            [test_failed,fail]=ltfatdiditfail(res+status,test_failed,0);
            fprintf(['CIRCSHIFT2 IP L:[%3i,%3i], shift:[%3i,%3i] %s %s %s %s\n'],Larr(lidx),Larr2(lidx),shift(1),shift(2),flags.complexity,complexstring,ltfatstatusstring(status),fail);

        end
    end
end


%
%   Url: http://ltfat.github.io/doc/libltfat/modules/libltfat/testing/mUnit/test_libltfat_circshift2.html

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

