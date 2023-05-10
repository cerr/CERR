function test_failed = test_libltfat_slidgtrealmp(varargin)
test_failed = 0;

fprintf(' ===============  %s ================ \n',upper(mfilename));

definput.flags.complexity={'double','single'};
[flags]=ltfatarghelper({},definput,varargin);
dataPtr = [flags.complexity, 'Ptr'];

[~,~,enuminfo]=libltfatprotofile;
LTFAT_FIRWIN = enuminfo.LTFAT_FIRWIN;

Larr =     [ 4*2048];
Warr =      [ 1];

bufLenInit = 100;
bufLenMax = 1000;

for initId = 0:1
    
for ii = 1:numel(Larr)
    L = Larr(ii);
    W = Warr(ii);
    parbuf = libpointer();
    slimpstate = libpointer();
    
    funname = makelibraryname('dgtrealmp_parbuf_init',flags.complexity,0);
    calllib('libltfat',funname, parbuf);
    
    funname = makelibraryname('dgtrealmp_parbuf_add_firwin',flags.complexity,0);
    calllib('libltfat',funname, parbuf, LTFAT_FIRWIN.LTFAT_BLACKMAN, 2048,  512, 2048);
    calllib('libltfat',funname, parbuf, LTFAT_FIRWIN.LTFAT_BLACKMAN, 512,  128, 512);
    
    funname = makelibraryname('dgtrealmp_setparbuf_maxit',flags.complexity,0);
    calllib('libltfat',funname, parbuf, L);
    
    funname = makelibraryname('dgtrealmp_setparbuf_iterstep',flags.complexity,0);
    calllib('libltfat',funname, parbuf, L);
    
    funname = makelibraryname('dgtrealmp_setparbuf_snrdb',flags.complexity,0);
    calllib('libltfat',funname, parbuf, 40);
    
    funname = makelibraryname('slidgtrealmp_init',flags.complexity,0);
    calllib('libltfat',funname, parbuf, L, W, bufLenMax, slimpstate);
    
    funname = makelibraryname('slidgtrealmp_getprocdelay',flags.complexity,0);
    procdelay = calllib('libltfat',funname,slimpstate);    
    initstr = 'INIT WIN';

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
        funname = makelibraryname('slidgtrealmp_execute',flags.complexity,0);
        status = calllib('libltfat',funname,slimpstate,bufInPtr,numel(slice),W,bufOutPtr);
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

    [test_failed,fail]=ltfatdiditfail(20*log10(norm(inshift)/norm(plotthat)) < 35 + any(bufOut(:)>10),test_failed);
    fprintf(['DGTREAL_PROCESSOR OP %s gl:%3i, W:%3i, %s %s %s\n'],initstr,L,W,flags.complexity,ltfatstatusstring(status),fail);

  

end
end






 
%
%   Url: http://ltfat.github.io/doc/libltfat/modules/libltfat/testing/mUnit/test_libltfat_slidgtrealmp.html

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
 
