function test_failed = test_libltfat_dgtrealwrapper(varargin)
test_failed = 0;

fprintf(' ===============  %s ================ \n',upper(mfilename));

definput.flags.complexity={'double','single'};
[flags]=ltfatarghelper({},definput,varargin);
dataPtr = [flags.complexity, 'Ptr'];

[~,~,enuminfo]=libltfatprotofile;
phaseconv = enuminfo.ltfat_phaseconvention;
hintstruct = enuminfo.ltfat_dgt_hint;

fftwflags = struct('FFTW_MEASURE',0,'FFTW_ESTIMATE',64,'FFTW_PATIENT',32,'FFTW_DESTROY_INPUT',1,...
    'FFTW_UNALIGNED',2,'FFTW_EXHAUSTIVE',8,'FFTW_PRESERVE_INPUT',16);

Larr  = [350 360   9   2];
glarr = [ 20  10   9   1];
aarr  = [ 10  10   3   1];
Marr  = [ 35  36   3   2];
Warr  = [  1   3   3   1];

for anasyn = {'ana','syn'}
dirstr = anasyn{1};
for hint = fieldnames(hintstruct).'
    hint = hint{1};
for idx = 1:numel(Larr)
    L = Larr(idx);
    W = Warr(idx);
    a = aarr(idx);
    M = Marr(idx);
    M2 = floor(M/2) + 1;
    gl = glarr(idx);
    
    N = L/a;
    g = randn(gl,1,flags.complexity);
    gPtr = libpointer(dataPtr,g);
    
    f = randn(L,W,flags.complexity);
    fPtr = libpointer(dataPtr,f);

    c = cast(randn(M2,N,W)+1i*randn(M2,N,W),flags.complexity);
    cout = complex2interleaved(c);
    coutPtr = libpointer(dataPtr,cout);
    

    plan = libpointer();
    funname = makelibraryname('dgtreal_init',flags.complexity,0);
    statusInit = calllib('libltfat',funname,gPtr,gl,L,W,a,M,fPtr,coutPtr,libpointer(),plan);
    
    if strcmp(dirstr,'ana') 
        funname = makelibraryname('dgtreal_execute_ana',flags.complexity,0);
        statusExecute = calllib('libltfat',funname,plan);
    
        truec = dgtreal(f,g,a,M);
        res = norm(reshape(truec,M2,N*W) - interleaved2complex(coutPtr.Value),'fro');
    elseif strcmp(dirstr,'syn')
        funname = makelibraryname('dgtreal_execute_syn',flags.complexity,0);
        statusExecute = calllib('libltfat',funname,plan);
    
        truef = idgtreal(c,{'dual',g},a,M);
        res = norm(truef - fPtr.Value,'fro');      
    end
    
    funname = makelibraryname('dgtreal_done',flags.complexity,0);
    statusDone = calllib('libltfat',funname,plan);
    
    [test_failed,fail]=ltfatdiditfail(res+statusInit,test_failed);
    fprintf(['DGTREAL FREQINV WP auto %s L:%3i, W:%3i, a:%3i, M:%3i %s %s %s\n'],dirstr,L,W,a,M,flags.complexity,ltfatstatusstring(statusExecute),fail);

    
    %%%%%%
    f = randn(L,W,flags.complexity);
    fPtr = libpointer(dataPtr,f);
    c = cast(randn(M2,N,W)+1i*randn(M2,N,W),flags.complexity);
    cout = complex2interleaved(c);
    coutPtr = libpointer(dataPtr,cout);
    
    params = calllib('libltfat','ltfat_dgt_params_allocdef');
    calllib('libltfat','ltfat_dgt_setpar_phaseconv',params,phaseconv.LTFAT_TIMEINV);
    calllib('libltfat','ltfat_dgt_setpar_hint',params,hintstruct.(hint));
    calllib('libltfat','ltfat_dgt_setpar_fftwflags',params,fftwflags.FFTW_MEASURE);
    
    plan = libpointer();
    funname = makelibraryname('dgtreal_init',flags.complexity,0);
    statusInit = calllib('libltfat',funname,gPtr,gl,L,W,a,M,fPtr,coutPtr,params,plan);
    
    if strcmp(dirstr,'ana') 
        funname = makelibraryname('dgtreal_execute_ana',flags.complexity,0);
        statusExecute = calllib('libltfat',funname,plan);
    
        truec = dgtreal(f,g,a,M,'timeinv');
        res = norm(reshape(truec,M2,N*W) - interleaved2complex(coutPtr.Value),'fro');
    elseif strcmp(dirstr,'syn')
        funname = makelibraryname('dgtreal_execute_syn',flags.complexity,0);
        statusExecute = calllib('libltfat',funname,plan);
    
        truef = idgtreal(c,{'dual',g},a,M,'timeinv');
        res = norm(truef - fPtr.Value,'fro');      
    end
    
    funname = makelibraryname('dgtreal_done',flags.complexity,0);
    statusDone = calllib('libltfat',funname,plan);
    
    calllib('libltfat','ltfat_dgt_params_free',params);
    
    [test_failed,fail]=ltfatdiditfail(res+statusInit,test_failed);
    fprintf(['DGTREAL TIMEINV WP %-4s %s L:%3i, W:%3i, a:%3i, M:%3i %s %s %s\n'],hint(15:end),dirstr,L,W,a,M,flags.complexity,ltfatstatusstring(statusExecute),fail);
    
    %%%%%%%
    f = randn(L,W,flags.complexity);
    fPtr = libpointer(dataPtr,f);
    c = cast(randn(M2,N,W)+1i*randn(M2,N,W),flags.complexity);
    cout = complex2interleaved(c);
    coutPtr = libpointer(dataPtr,cout);
    
    params = calllib('libltfat','ltfat_dgt_params_allocdef');
    calllib('libltfat','ltfat_dgt_setpar_phaseconv',params,phaseconv.LTFAT_TIMEINV);
    calllib('libltfat','ltfat_dgt_setpar_hint',params,hintstruct.(hint));
    calllib('libltfat','ltfat_dgt_setpar_fftwflags',params,fftwflags.FFTW_ESTIMATE);
    
    plan = libpointer();
    funname = makelibraryname('dgtreal_init',flags.complexity,0);
    statusInit = calllib('libltfat',funname,gPtr,gl,L,W,a,M,libpointer(),libpointer(),params,plan);
    
    if strcmp(dirstr,'ana') 
        funname = makelibraryname('dgtreal_execute_ana_newarray',flags.complexity,0);
        statusExecute = calllib('libltfat',funname,plan,fPtr,coutPtr);
    
        truec = dgtreal(f,g,a,M,'timeinv');
        res = norm(reshape(truec,M2,N*W) - interleaved2complex(coutPtr.Value),'fro');
    elseif strcmp(dirstr,'syn')
        funname = makelibraryname('dgtreal_execute_syn_newarray',flags.complexity,0);
        statusExecute = calllib('libltfat',funname,plan,coutPtr,fPtr);
    
        truef = idgtreal(c,{'dual',g},a,M,'timeinv');
        res = norm(truef - fPtr.Value,'fro');      
    end
    
    funname = makelibraryname('dgtreal_done',flags.complexity,0);
    statusDone = calllib('libltfat',funname,plan);
    
    calllib('libltfat','ltfat_dgt_params_free',params);
    
    [test_failed,fail]=ltfatdiditfail(res+statusInit,test_failed);
    fprintf(['DGTREAL TIMEINV WP %-4s %s L:%3i, W:%3i, a:%3i, M:%3i %s %s %s\n'],hint(15:end),dirstr,L,W,a,M,flags.complexity,ltfatstatusstring(statusExecute),fail);    
    
    
end
end
end



%
%   Url: http://ltfat.github.io/doc/libltfat/modules/libltfat/testing/mUnit/test_libltfat_dgtrealwrapper.html

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

