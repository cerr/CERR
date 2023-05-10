function test_failed = test_libltfat_fold(varargin)

test_failed = 0;

fprintf(' ===============  %s ================ \n',upper(mfilename));

definput.flags.complexity={'double','single'};
[flags]=ltfatarghelper({},definput,varargin);
dataPtr = [flags.complexity, 'Ptr'];

Larr =     [10 11  10   10  101 101];
Lfoldarr = [3  16   3    3    1   2];
shiftarr = [0   0  -5 -101   -3  11];

for do_complex = 0:1
    complexstring = '';
    if do_complex, complexstring = 'complex'; end
    funname = makelibraryname('fold_array',flags.complexity,do_complex);

    for lId = 1:numel(Larr)
        L     = Larr(lId);
        Lfold = Lfoldarr(lId);
        shift = shiftarr(lId);

        if do_complex
            z = (1:max(L,Lfold)) + 1i*(max(L,Lfold):-1:1);
            z(L+1:end) = 0;
            zi = complex2interleaved(z);
            zout = complex2interleaved(randn(1,Lfold) + 1i*randn(1,Lfold));
        else
            z = (1:max(L,Lfold));
            z(L+1:end) = 0;
            zi = z;
            zout = randn(1,Lfold);
        end

        ziPtr = libpointer(dataPtr,zi);
        zoutPtr = libpointer(dataPtr,zout);

        periods = ceil(L/Lfold);
        fext = postpad(z,periods*Lfold);
        ffoldtrue = circshift(sum(reshape(fext, Lfold, periods),2).',[0,shift]);
        ffold2ndtrue = sum(reshape(circshift(fext,[0,shift]), Lfold, periods),2).';

        errTrues = norm(ffoldtrue - ffold2ndtrue);


        status = calllib('libltfat',funname,ziPtr,L,shift,Lfold,zoutPtr);

        if do_complex
            res = norm(ffoldtrue - interleaved2complex(zoutPtr.Value));
        else
            res = norm(ffoldtrue - zoutPtr.Value);
        end

        [test_failed,fail]=ltfatdiditfail(res+status,test_failed,0);
        fprintf(['FOLD OP L:%3i, Lfold:%3i, shift:%3i, %s %s %s %s\n'],L,Lfold,shift,flags.complexity,complexstring,ltfatstatusstring(status),fail);

        status = calllib('libltfat',funname,ziPtr,L,shift,Lfold,ziPtr);

        if do_complex
            res = norm(ffoldtrue - postpad(interleaved2complex(ziPtr.Value),Lfold));
        else
            res = norm(ffoldtrue - ziPtr.Value(1:Lfold));
        end

        [test_failed,fail]=ltfatdiditfail(res+status,test_failed,0);
        fprintf(['FOLD IP L:%3i, Lfold:%3i, shift:%3i, %s %s %s %s\n'],L,Lfold,shift,flags.complexity,complexstring,ltfatstatusstring(status),fail);
    end
end

%interleaved2complex(zoutPtr.Value)
%
%   Url: http://ltfat.github.io/doc/libltfat/modules/libltfat/testing/mUnit/test_libltfat_fold.html

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




