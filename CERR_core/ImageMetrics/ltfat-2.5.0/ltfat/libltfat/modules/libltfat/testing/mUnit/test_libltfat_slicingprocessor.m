function test_failed = test_libltfat_slicingprocessor(varargin)
test_failed = 0;

fprintf(' ===============  %s ================ \n',upper(mfilename));

definput.flags.complexity={'double','single'};
[flags]=ltfatarghelper({},definput,varargin);
dataPtr = [flags.complexity, 'Ptr'];

[~,~,enuminfo]=libltfatprotofile;
LTFAT_FIRWIN = enuminfo.LTFAT_FIRWIN;

glarr =     [ 5000,  512, 1024, 90];
Warr =      [1,   2,    1,  3];

bufLenInit = 10;
bufLenMax = 1000;

for initId = 0:1
    
for ii = 1:numel(glarr)
    gl = glarr(ii);
    
    W = Warr(ii);
    plan = libpointer();

    funname = makelibraryname('slicing_processor_init',flags.complexity,0);
    calllib('libltfat',funname, gl, floor(gl/5), floor(gl/5), W,bufLenMax,plan);
    initstr = 'INIT WIN';
    
    funname = makelibraryname('slicing_processor_getprocdelay',flags.complexity,0);
    procdelay = calllib('libltfat',funname, plan);

    [bufIn,fs] = gspi;
    bufIn = cast(bufIn,flags.complexity);
    bufIn = bsxfun(@times, repmat(bufIn,1,W), [1, rand(1,W-1,flags.complexity) + 1]);

    bufOut = 1000*ones(size(bufIn),flags.complexity);
    L = size(bufIn,1);
    status = 0;
    startIdx = 1;
    bufLen = bufLenInit;
    while startIdx <= L
        stopIdx = min([startIdx + bufLen - 1,L]);
        slice = startIdx : stopIdx;
        buf = bufIn(slice,:);
        bufInPtr = libpointer(dataPtr,buf);
        bufOutPtr = libpointer(dataPtr,randn(size(buf),flags.complexity));

        % Matlab automatically converts Ptr to PtrPtr
        funname = makelibraryname('slicing_processor_execute_compact',flags.complexity,0);
        status = calllib('libltfat',funname,plan,bufInPtr,numel(slice),W,bufOutPtr);
        if status
            break;
        end

        bufOut(slice,:) = bufOutPtr.Value;
        startIdx = stopIdx + 1;
        bufLen = randi(bufLenMax);
    end

    inshift = circshift(bufIn,(procdelay));
    inshift(1:(procdelay),:) = 0;
    plotthat = [bufOut - inshift];
    plotthat(end-(procdelay):end,:) = 0;

    [test_failed,fail]=ltfatdiditfail(norm(plotthat) + any(bufOut(:)>10),test_failed);
    fprintf(['DGTREAL_PROCESSOR OP %s gl:%3i, W:%3i, %s %s %s\n'],initstr,gl,W,flags.complexity,ltfatstatusstring(status),fail);

    funname = makelibraryname('slicing_processor_done',flags.complexity,0);
    calllib('libltfat',funname,plan);
    
    
    plan = libpointer();
    funname = makelibraryname('slicing_processor_init',flags.complexity,0);
    calllib('libltfat',funname, gl, floor(gl/5), floor(gl/5), W,bufLenMax, plan);
    

    bufOut = 1000*ones(size(bufIn),flags.complexity);
    L = size(bufIn,1);
    status = 0;
    startIdx = 1;
    bufLen = bufLenInit;
    while startIdx <= L
        stopIdx = min([startIdx + bufLen - 1,L]);
        slice = startIdx : stopIdx;
        buf = bufIn(slice,:);
        bufInPtr = libpointer(dataPtr,buf);

        % Matlab automatically converts Ptr to PtrPtr
        funname = makelibraryname('slicing_processor_execute_compact',flags.complexity,0);
        status = calllib('libltfat',funname,plan,bufInPtr,numel(slice),W,bufInPtr);
        if status
            break;
        end

        bufOut(slice,:) = bufInPtr.Value;
        startIdx = stopIdx + 1;
        bufLen = randi(bufLenMax);
    end

    inshift = circshift(bufIn,(procdelay));
    inshift(1:(procdelay),:) = 0;
    plotthat = [bufOut - inshift];
    plotthat(end-(gl-1):end,:) = 0;

    [test_failed,fail]=ltfatdiditfail(norm(plotthat) + any(bufOut(:)>10),test_failed);
    fprintf(['DGTREAL_PROCESSOR IP %s gl:%3i, W:%3i, %s %s %s\n'],initstr,gl,W,flags.complexity,ltfatstatusstring(status),fail);

    funname = makelibraryname('slicing_processor_done',flags.complexity,0);
    calllib('libltfat',funname,plan);
end
end






 
%
%   Url: http://ltfat.github.io/doc/libltfat/modules/libltfat/testing/mUnit/test_libltfat_slicingprocessor.html

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
 
