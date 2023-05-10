function [test_failed, atomsArr]= test_libltfat_dgtrealmp(varargin)
test_failed = 0;
doplot = 0;

fprintf(' ===============  %s ================ \n',upper(mfilename));

definput.flags.complexity={'double','single'};
[flags]=ltfatarghelper({},definput,varargin);
dataPtr = [flags.complexity, 'Ptr'];
dataPtrPtr = [flags.complexity, 'PtrPtr'];

intbitsize = 8*calllib('libltfat','ltfat_int_size');
intPtr = sprintf('int%dPtr',intbitsize);

[~,~,enuminfo]=libltfatprotofile;
phaseconv = enuminfo.ltfat_phaseconvention;
hintstruct = enuminfo.ltfat_dgt_hint;


algmpstruct = enuminfo.ltfat_dgtmp_alg;
statusenum = enuminfo.ltfat_dgtmp_status;

fftwflags = struct('FFTW_MEASURE',0,'FFTW_ESTIMATE',64,'FFTW_PATIENT',32,'FFTW_DESTROY_INPUT',1,...
    'FFTW_UNALIGNED',2,'FFTW_EXHAUSTIVE',8,'FFTW_PRESERVE_INPUT',16);

base = 2048;
Larr  = [128* base   9   2];
glarr = [ base  10   9   1];
aarr  = [   base/4   10   3   1];
Marr  = [ base  36   3   2];
Warr  = [  1   3   3   1];
errtoldb = -40;

atomsArr= [];

for idx = 1:1%numel(Larr)
    
%     L = Larr(idx);
%     W = Warr(idx);
%     a = aarr(idx);
%     M = Marr(idx);
%     M2 = floor(M/2) + 1;
%     gl = glarr(idx);
% f = randn(L,W,flags.complexity);
%
%   Url: http://ltfat.github.io/doc/libltfat/modules/libltfat/testing/mUnit/test_libltfat_dgtrealmp.html

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



for ii=  57

%filename = sprintf('~/Desktop/SQAM/%02d.wav',ii);
%disp(filename);
    
%[f,fs] = wavload(filename);
[f,fs] = gspi;

%f = postpad(f,fs);
f = cast(f,flags.complexity);
f = f(:,1);

[Ls,W] = size(f(:,1));
%Ls = min([Ls,2*fs]);
% Ls = 5*2048;
%Ls = 20000;
% f = postpad(f(fs:fs+Ls),Ls);
% f = zeros(Ls,1);
% f(1) = 1;
%f = [zeros(10*1024,1);f;zeros(10*1024,1);];

Ls = numel(f);
%f(:) = pconv(f,fir2long(firwin('hann',1),Ls));
%f = [zeros(100,1);f(6*fs+1:7*fs)];

%f = pconv(f,fir2long(firwin('hann',1),numel(f)));
%f = postpad(f,Ls+fs);
%f = [zeros(fs,1);postpad(f(fs:end,1),Ls);zeros(fs,1)];
W = 1;
%Ls = numel(f);
a  = [     1024,   128 ,   256, 128,  64,  1024,   512, 16, 256];
M  = [     4096,  2048,  1024, 512,  256, 2048, 32, 512];
gl = [     4096,  2048,  1024, 512,  256, 2048,   2048,  32, 512 ];
M2 = floor(M/2) + 1;
P = [2];
Psize = numel(P);

L = dgtlength(Ls,max(a(P)),max(M(P)));
%L = dgtlength(Ls,a(1),M(1));
f = postpad(f,L);

%f(2:2:end) = -f(2:2:end);
cphaseconv = phaseconv.LTFAT_TIMEINV;
mphaseconv = 'timeinv';
if cphaseconv == phaseconv.LTFAT_FREQINV
    mphaseconv = 'freqinv';
end
%f(:) = linspace(0,1,L); 

    
N = L./a;
%g = randn(gl,1,flags.complexity);

gCell = cell(Psize,1);
for p=1:Psize
    gCell{p} = cast(firwin('blackman',gl(P(p)),'peak'),flags.complexity);
%     if p==1
%        gg = cast(firwin('tria',gl(P(p))/2,'peak'),flags.complexity);
%        gCell{p}(end/2 +1:end) = 0;
%        gCell{p}(end- numel(gg(end/2+1:end)) +1:end) = gg(end/2+1:end); 
%     end
    gCell{p} = normalize(gCell{p},'2');
%        [A,B] = gabframebounds(gCell{p},a(P(p)),M(P(p)));
%     gCell{p} = cast(gabwin({'gauss',a(p)*M(p)/L},a(p),M(p),L),flags.complexity); 
%     [idx] = find(gCell{p} < 1e-6 ,1,'first');
%     gCell{p} = middlepad(gCell{p},2*idx-1);
%     gl(p) = numel(gCell{p});
end
g = cell2mat(gCell);
 
gPtr = libpointer(dataPtr,g);
glPtr = libpointer(intPtr,gl(P));
aPtr  = libpointer(intPtr,a(P));
MPtr  = libpointer(intPtr,M(P));


fPtr = libpointer(dataPtr,f);

fout = randn(L,numel(P),flags.complexity);
foutPtr = libpointer(dataPtr,fout);

sizeaccum = 0;
for p=1:Psize
    sizeaccum = sizeaccum + M2(P(p))*N(P(p))*W;
end

cout = complex2interleaved(...
cast(zeros(sizeaccum,1)+...
         1i*zeros(sizeaccum,1),flags.complexity));
coutPtr = libpointer(dataPtr,cout);


%ctrue = dgt(f,g(1:gl(1)),a(1),M(1));
atoms = sizeaccum*10;
%atoms = 13;

tic;
params = calllib('libltfat','ltfat_dgtmp_params_allocdef');
calllib('libltfat','ltfat_dgtmp_setpar_maxatoms',params,atoms);
calllib('libltfat','ltfat_dgtmp_setpar_maxit',params,2*atoms);
calllib('libltfat','ltfat_dgtmp_setpar_errtoldb',params,errtoldb);
calllib('libltfat','ltfat_dgtmp_setpar_kernrelthr',params,1e-4);
calllib('libltfat','ltfat_dgtmp_setpar_phaseconv',params,cphaseconv);
calllib('libltfat','ltfat_dgtmp_setpar_pedanticsearch',params,1);
calllib('libltfat','ltfat_dgtmp_setpar_alg',params,algmpstruct.ltfat_dgtmp_alg_loccyclicmp);
%calllib('libltfat','ltfat_dgtmp_setpar_alg',params,algmpstruct.ltfat_dgtmp_alg_LocOMP);
calllib('libltfat','ltfat_dgtmp_setpar_iterstep',params,1e6);
calllib('libltfat','ltfat_dgtmp_setpar_cycles',params,1);


plan = libpointer();
funname = makelibraryname('dgtrealmp_init_gen_compact',flags.complexity,0);
statusInit = calllib('libltfat',funname,gPtr,glPtr,...
    L,Psize,aPtr,MPtr,params,plan);
tinit = toc;

calllib('libltfat','ltfat_dgtmp_params_free',params);

tic
funname = makelibraryname('dgtrealmp_reset',flags.complexity,0);
statusReset = calllib('libltfat',funname,plan,fPtr);
t1 = toc;

 cres1 = complex2interleaved(...
 cast(randn(sizeaccum,1)+...
          1i*randn(sizeaccum,1),flags.complexity));
cresPtr = libpointer(dataPtr,cres1);

if doplot
funname = makelibraryname('dgtrealmp_getresidualcoef_compact',flags.complexity,0);
calllib('libltfat',funname,plan,cresPtr);
cres2 = reshape(postpad(interleaved2complex(cresPtr.value),M2(P(1))*N(P(1))),M2(P(1)),N(P(1)));
figure(2); plotdgtreal(cres2,1,100,'clim',[-90,10]);
end

tic
 funname = makelibraryname('dgtrealmp_execute_compact',flags.complexity,0);
 statusExecute = calllib('libltfat',funname,plan,fPtr,coutPtr,foutPtr);
 %funname = makelibraryname('dgtrealmp_execute_niters_compact',flags.complexity,0);
 %statusExecute = calllib('libltfat',funname,plan,50*atoms,coutPtr);
t2 =toc;

cout2 = interleaved2complex(coutPtr.value);
sizeaccum = 0;
for p=1:Psize
    nextsizeaccum = sizeaccum + M2(P(p))*N(P(p))*W;
    figure(4+p); plotdgtreal(reshape(postpad(cout2(1+sizeaccum:nextsizeaccum), M2(P(p))*N(P(p)) ),M2(P(p)),N(P(p))),a(P(p)),M(P(p)),'clim',[-90,10]);
    sizeaccum = nextsizeaccum;
    %ylim([0,0.01]);
end

% funname = makelibraryname('dgtrealmp_revert',flags.complexity,0);
% calllib('libltfat',funname,plan,coutPtr);

%%%%%%%%%%%%%%
errdb = libpointer('doublePtr',[1]);
funname = makelibraryname('dgtrealmp_get_errdb',flags.complexity,0);
calllib('libltfat',funname,plan,errdb);
err2 = errdb.value;
%%%%%%%%%%%%%%
%%%%%%%%%%%%%%
numitersPtr = libpointer('uint64Ptr',[1]);
funname = makelibraryname('dgtrealmp_get_numiters',flags.complexity,0);
calllib('libltfat',funname,plan,numitersPtr);
%%%%%%%%%%%%%%
%%%%%%%%%%%%%%
numatomsPtr = libpointer('uint64Ptr',[1]);
funname = makelibraryname('dgtrealmp_get_numatoms',flags.complexity,0);
calllib('libltfat',funname,plan,numatomsPtr);
%%%%%%%%%%%%%%

if doplot
cres2 = complex2interleaved(...
cast(randn(sizeaccum,1)+...
         1i*randn(sizeaccum,1),flags.complexity));
cresPtr = libpointer(dataPtr,cres2);
 
funname = makelibraryname('dgtrealmp_getresidualcoef_compact',flags.complexity,0);
calllib('libltfat',funname,plan,cresPtr);

cres = interleaved2complex(cresPtr.value);
sizeaccum = 0;
for p=1:Psize
    nextsizeaccum = sizeaccum + M2(P(p))*N(P(p))*W;
    figure(10+p); plotdgtreal(reshape(postpad(cres(1+sizeaccum:nextsizeaccum), M2(P(p))*N(P(p)) ),M2(P(p)),N(P(p))),1,100,'clim',[-90,10]);
    sizeaccum = nextsizeaccum;
end
end


%cres2 = reshape( postpad( interleaved2complex(cresPtr.value),M2(P(1))*N(P(1))  ),M2(P(1)),N(P(1)));
%figure(3); plotdgtreal(cres2,1,100,'clim',[-90,10]);
%figure(4); plotdgtreal(cres1-cres2,1,100,'dynrange',90);


fprintf('Init %.3f, reset %.3f, execute %.3f, both %.3f seconds, status %s.\n',tinit,t1,t2,t1+t2,dgtrealmpstring(statusExecute));



clear coutPtr cout
atoms = numel(find(abs(cout2(:))));

coutCell = cell(Psize,1);
sizeaccum = 0;
fout(:) = 0;
for p=1:Psize
    coutCell{p} = cout2(sizeaccum +1: sizeaccum + M2(P(p))*N(P(p))*W);
    coutCell{p} = reshape(coutCell{p},M2(P(p)),N(P(p)),W);
    sizeaccum = sizeaccum + M2(P(p))*N(P(p))*W;
    fout(:,p) = idgtreal(coutCell{p},gCell{p},a(P(p)),M(P(p)),mphaseconv);
end

indatoms = cellfun(@(a) numel(find(abs(a(:)))), coutCell);
atomstr = sprintf('%d,',indatoms);

clear cout2
figure(1);
plot((0:L-1)/fs,[fPtr.value, fout]);

errdb = 20*log10(norm(fPtr.value -sum(fout,2))/norm(fPtr.value));

errdb22 = libpointer(dataPtr,[1]);
foutPtr = libpointer(dataPtr,sum(fout,2));
funname = makelibraryname('snr',flags.complexity,0);
statusExecute = calllib('libltfat',funname,fPtr,foutPtr,L,errdb22);
%soundsc(fout,44100);pause(4);

errdb22.value;

fprintf('%i(%i) [%s] atoms (from %i), %i iters, sparsity %.3f, L=%i, %i atoms/s\nErr: True: %.8f dB, En: %.8f dB,\n',...
     atoms, numatomsPtr.value, atomstr(1:end-1),sum(M2(P(p))*L./a(P(p))),numitersPtr.value,atoms/L,L,atoms/t2, errdb22.value,err2);

shg; 

funname = makelibraryname('dgtrealmp_done',flags.complexity,0);
statusDone = calllib('libltfat',funname,plan);


  atomsArr(end + 1) = atoms;
  [test_failed,fail]=ltfatdiditfail(abs(errdb - errtoldb)>0.1 ,test_failed);
    %[test_failed,fail]=ltfatdiditfail(res+statusInit,test_failed);
    %fprintf(['DGTREAL FREQINV WP auto %s L:%3i, W:%3i, a:%3i, M:%3i %s %s %s\n'],dirstr,L,W,a,M,flags.complexity,ltfatstatusstring(statusExecute),fail);
 %drawnow  
   
end
end


function sstring=dgtrealmpstring(status)

[~,~,enuminfo]=libltfatprotofile;

map = structfun(@(a) a==status ,enuminfo.ltfat_dgtmp_status);
names = fieldnames(enuminfo.ltfat_dgtmp_status);
sstring = names{map};



