function test_failed = test_libltfat_rtdgtreal(varargin)
test_failed = 0;
return;
fprintf(' ===============  %s ================ \n',upper(mfilename));

definput.flags.complexity={'double','single'};
[flags]=ltfatarghelper({},definput,varargin);
dataPtr = [flags.complexity, 'Ptr'];

[~,~,enuminfo]=libltfatprotofile;
LTFAT_FIRWIN = enuminfo.LTFAT_FIRWIN;
rdgt_phasetype = enuminfo.rtdgt_phasetype;

glarr =     [500,  512, 1024, 90];
Marr =      [1000, 512, 2048, 101];
aarr =      [100 , 256,  256, 40];
Warr =      [10  ,   2,    1,  3];

f = greasy;

a = 16;
gl = 60;
gdl = gl;
M = 64;
L = dgtlength(numel(f),a,M);
M2 = floor(M/2) + 1;
g = zeros(gl,1);
gd = zeros(gdl,1);
gPtr = libpointer(dataPtr,g);
gdPtr = libpointer(dataPtr,gd);
funname = makelibraryname('firwin',flags.complexity,0);
calllib('libltfat',funname,LTFAT_FIRWIN.LTFAT_HANN,gl,gPtr);

funname = makelibraryname('gabdual_painless',flags.complexity,0);
prd=calllib('libltfat',funname,gPtr,gl,a,M,gdPtr);
if prd
    warning('This is not painless frame');
    g2Ptr = libpointer(dataPtr,fir2long(gPtr.Value,L));
    gdPtr = libpointer(dataPtr,fir2long(gd,L));
    funname = makelibraryname('gabdual_long',flags.complexity,0);
    calllib('libltfat',funname,g2Ptr,L,1,a,M,gdPtr);
    gdl = L;
end

cframes = signal2frames(f,gl,a,M);
% cframes2 = bsxfun(@times,cframes,M*gPtr.Value.*gdPtr.Value);
% f2 = frames2signal(cframes2,gl,a);
% norm(f-postpad(f2,numel(f)))
%
%   Url: http://ltfat.github.io/doc/libltfat/modules/libltfat/testing/mUnit/test_libltfat_rtdgtreal.html

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
N = size(cframes,2);


%ctrue = fftreal(ifftshift(bsxfun(@times,cframes,fftshift(gPtr.Value)),1));
ctrue = dgtreal(f,gPtr.Value,a,M,'timeinv');
p = libpointer();
pinv = libpointer();

funname = makelibraryname('rtdgtreal_init',flags.complexity,0);
calllib('libltfat',funname,gPtr,gl,M,rdgt_phasetype.LTFAT_RTDGTPHASE_ZERO,p);
funname = makelibraryname('rtidgtreal_init',flags.complexity,0);
calllib('libltfat',funname,gdPtr,gdl,M,rdgt_phasetype.LTFAT_RTDGTPHASE_ZERO,pinv);

c = zeros(2*M2,N);
f2 = zeros(gdl,N);
fPtr = libpointer(dataPtr,cframes);
cPtr = libpointer(dataPtr,c);
f2Ptr = libpointer(dataPtr,f2);

calllib('libltfat','ltfat_rtdgtreal_execute_d',p,fPtr,N,cPtr);
norm(ctrue - interleaved2complex(cPtr.Value),'fro')
calllib('libltfat','ltfat_rtidgtreal_execute_d',pinv,cPtr,N,f2Ptr);

frec = frames2signal(f2Ptr.Value,gdl,a);
figure(1);plot([f-postpad(frec,numel(f))]);

fprintf('Coef error. %d \n', norm(ctrue-interleaved2complex(cPtr.Value),'fro'));
fprintf('Rec error. %d \n', norm(f-postpad(frec,numel(f))));

figure(2);plotdgtreal(abs(ctrue)-abs(interleaved2complex(cPtr.Value)),a,M,'linabs');
%imagesc(abs(interleaved2complex(cPtr.Value))./abs(ctrue))

calllib('libltfat','ltfat_rtdgtreal_done_d',p);
calllib('libltfat','ltfat_rtidgtreal_done_d',pinv);

%norm(long2fir(gdtrue,gl) - gdPtr.Value)

function cframes = signal2frames(f,gl,a,M)

[Ls,~] = size(f);
L=dgtlength(Ls,a,M);
N = L/a;
f = postpad(f,L);

cframes = zeros(gl,N,1);

idxrange = -floor(gl/2):ceil(gl/2)-1;

for n=0:N-1
    idx = mod(n*a + idxrange,L) + 1;
    cframes(:,n+1) = f(idx);
end

function f = frames2signal(cframes,gl,a)

N = size(cframes,2);
L = N*a;
f = zeros(L,1);

idxrange = -floor(gl/2):ceil(gl/2)-1;
for n=0:N-1
    idx = mod(n*a + idxrange,L) + 1;
    f(idx) = f(idx) + cframes(:,n+1);
end


