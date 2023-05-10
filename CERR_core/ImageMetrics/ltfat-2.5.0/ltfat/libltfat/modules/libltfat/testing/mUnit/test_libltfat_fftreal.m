function test_failed = test_libltfat_fftreal(varargin)
test_failed = 0;

fprintf(' ===============  %s ================ \n',upper(mfilename));

definput.flags.complexity={'double','single'};
[flags]=ltfatarghelper({},definput,varargin);
dataPtr = [flags.complexity, 'Ptr'];

[~,~,enuminfo]=libltfatprotofile;
phaseconv = enuminfo.ltfat_phaseconvention;

fftwflags = struct('FFTW_MEASURE',0,'FFTW_ESTIMATE',64,'FFTW_PATIENT',32,'FFTW_DESTROY_INPUT',1,...
    'FFTW_UNALIGNED',2,'FFTW_EXHAUSTIVE',8,'FFTW_PRESERVE_INPUT',16);

Larr  = [351 350   9   1];
Warr  = [  3   3   1   1];

for idx = 1:numel(Larr)
    L = Larr(idx);
    W = Warr(idx);
    M2 = floor(L/2) + 1;

    f = randn(L,W,flags.complexity);   
    fPtr = libpointer(dataPtr,f);

    c = cast(randn(M2,W)+1i*randn(M2,W),flags.complexity);
    cout = complex2interleaved(c);
    coutPtr = libpointer(dataPtr,cout);

    truec = fftreal(f);

    funname = makelibraryname('fftreal',flags.complexity,0);
    status = calllib('libltfat',funname,fPtr,L,W,coutPtr);

    res = norm(truec - interleaved2complex(coutPtr.Value),'fro');
    [test_failed,fail]=ltfatdiditfail(res+status,test_failed);
    fprintf(['FFT   L:%3i, W:%3i, %s %s %s\n'],L,W,flags.complexity,ltfatstatusstring(status),fail);
    
    % With plan
    c = cast(randn(M2,W),flags.complexity);
    cout = complex2interleaved(c);
    coutPtr = libpointer(dataPtr,cout);

    plan = libpointer();
    funname = makelibraryname('fftreal_init',flags.complexity,0);
    statusInit = calllib('libltfat',funname,L,W,fPtr,coutPtr, fftwflags.FFTW_ESTIMATE, plan);

    funname = makelibraryname('fftreal_execute',flags.complexity,0);
    statusExecute = calllib('libltfat',funname,plan);

    res = norm(truec - interleaved2complex(coutPtr.Value),'fro');
    [test_failed,fail]=ltfatdiditfail(res+statusInit,test_failed);
    fprintf(['FFT L:%3i, W:%3i, %s %s %s\n'],L,W,flags.complexity,ltfatstatusstring(status),fail);

    c = cast(randn(M2,W),flags.complexity);
    cout = complex2interleaved(c);
    coutPtr = libpointer(dataPtr,cout);

    funname = makelibraryname('fftreal_execute_newarray',flags.complexity,0);
    statusExecute = calllib('libltfat',funname,plan,fPtr,coutPtr);

    res = norm(truec - interleaved2complex(coutPtr.Value),'fro');
    [test_failed,fail]=ltfatdiditfail(res+statusInit,test_failed);
    fprintf(['FFT L:%3i, W:%3i, %s %s %s\n'],L,W,flags.complexity,ltfatstatusstring(status),fail);        

    funname = makelibraryname('fftreal_done',flags.complexity,0);
    statusDone = calllib('libltfat',funname,plan);


    %%%%%% Inplace
    c = postpad(f, 2*M2);
    %cout = complex2interleaved(c);
    coutPtr = libpointer(dataPtr,c);

    plan = libpointer();
    funname = makelibraryname('fftreal_init',flags.complexity,0);
    statusInit = calllib('libltfat',funname,L,W, coutPtr, coutPtr, fftwflags.FFTW_ESTIMATE, plan);

    funname = makelibraryname('fftreal_execute',flags.complexity,0);
    statusExecute = calllib('libltfat',funname,plan);

    ctmp = interleaved2complex(coutPtr.Value);
    res = norm(truec - ctmp(1:M2,:),'fro');
    [test_failed,fail]=ltfatdiditfail(res+statusInit,test_failed);
    fprintf(['FFT L:%3i, W:%3i, %s %s %s\n'],L,W,flags.complexity,ltfatstatusstring(status),fail);

    c = postpad(f, 2*M2);
    %cout = complex2interleaved(c);
    coutPtr = libpointer(dataPtr,c);

    funname = makelibraryname('fftreal_execute_newarray',flags.complexity,0);
    statusExecute = calllib('libltfat',funname,plan,coutPtr,coutPtr);

    ctmp = interleaved2complex(coutPtr.Value);
    res = norm(truec - ctmp(1:M2,:),'fro');
    [test_failed,fail]=ltfatdiditfail(res+statusInit,test_failed);
    fprintf(['FFT L:%3i, W:%3i, %s %s %s\n'],L,W,flags.complexity,ltfatstatusstring(status),fail);        

    funname = makelibraryname('fftreal_done',flags.complexity,0);
    statusDone = calllib('libltfat',funname,plan);
end



%
%   Url: http://ltfat.github.io/doc/libltfat/modules/libltfat/testing/mUnit/test_libltfat_fftreal.html

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

