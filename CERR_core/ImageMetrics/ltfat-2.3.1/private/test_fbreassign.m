function test_failed = test_fbreassign(varargin)
test_failed = 0;
try

do_time = any(strcmp('time',varargin));
do_all = any(strcmp('all',varargin));

L = 44100;

%-*- texinfo -*-
%@deftypefn {Function} test_fbreassign
%@verbatim
%f = exp(2*pi*1i*((0:44099)/168))';
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/test_fbreassign.html}
%@end deftypefn

% Copyright (C) 2005-2016 Peter L. Soendergaard <peter@sonderport.dk>.
% This file is part of LTFAT version 2.3.1
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
f = sin(2*pi*((0:44099)/35+((0:44099)/300).^2)) + ...
    sin(2*pi*((0:44099)/10+((0:44099)/300).^2)) + ...
    sin(2*pi*((0:44099)/5-((0:44099)/450).^2));
f = 0.7*f';
%f=gspi;

%f = zeros(L,1);
%f(10000) = 1;

% wavwrite(f,44100,16,'testclean.wav');
% f = gspi;
% f = f(44101:88200);
% fn = rand(44100,1)-.5;
% fn = fn/norm(fn)*norm(f);
% f = f+fn;
% wavwrite(f,44100,16,'testnoisy.wav');
% f = gspi;
% f = f(44101:88200);

fs = 44100;

[g,a,fc,L]=erbfilters(fs,44100,'fractional','spacing',1/12,'warped','complex');
if length(a) < length(g)
    a = [a;a(end-1:-1:2,:)];
end
if do_time, tic; end
[tgrad,fgrad,cs0,c]=filterbankphasegrad(f,g,a); 
if do_time, PGtime = toc; fprintf('PGtime=%d\n',PGtime); end

if do_time, tic; end
fc = cent_freqs(fs,fc);
if do_time, CFtime = toc; fprintf('CFtime=%d\n',CFtime); end 
if do_time, tic; end
[sr0,arg1,arg2]=filterbankreassign(cs0,tgrad,fgrad,a,fc); 
if do_time, RAtime = toc; fprintf('RAtime=%d\n',RAtime); end 
figure(1); clf;
subplot(211);
plotfilterbank(cs0,a,'fc',fs/2*fc,'db','dynrange',60);
title('ERBlet spectrogram of 3 chirps');
subplot(212);  plotfilterbank(sr0,a,'fc',fs/2*fc,'db','dynrange',60);
title('Reassigned ERBlet spectrogram of 3 chirps');
colormap(flipud(gray));



%% 
clear g g2 g3
Lg = 28;
a0 = 8*ones(168,1);
cfreq0 = [0:84,-83:-1].'/84;
gg = fftshift(firwin('hann',Lg));

for kk = 0:167
g{kk+1}.h = gg;
g{kk+1}.fc = modcent(kk/84,2);
g{kk+1}.offset = -Lg/2; 
g{kk+1}.realonly = 0; 
end

if do_time, tic; end
[tgrad,fgrad,c_s]=filterbankphasegrad(f,g,a0,filterbanklength(L,a0)); 
if do_time, PGtimeFIR = toc; fprintf('PGtimeFIR=%d\n',PGtimeFIR); end
if do_time, tic; end
[sr,arg0,arg1]=filterbankreassign(c_s,tgrad,fgrad,a0,cfreq0);
if do_time, RAtimeFIR = toc; fprintf('RAtimeFIR=%d\n',RAtimeFIR); end

Lg = 882;
a = 90*ones(882,1);
cfreq1 = [0:441,-440:-1].'/441;
gg = fftshift(firwin('hann',Lg));%.*exp(-2*pi*1i*100*(-Lg/2:Lg/2-1).'./L);
for kk = 0:881
g2{kk+1}.H = gg;
g2{kk+1}.L = L;
g2{kk+1}.foff = kk*L/882-Lg/2;
g2{kk+1}.realonly = 0; 
g3{kk+1}.L = L;
g3{kk+1}.H = comp_transferfunction(g2{kk+1},L);
g3{kk+1}.foff = 0;
g3{kk+1}.realonly = 0; 
end

figure(2); clf; subplot(311); 
plotfilterbank(sr,a0,'fc',fs/2*cfreq0,'linabs');

if do_time, tic; end
[tgrad,fgrad,c_s2]=filterbankphasegrad(f,g2,a,L);
if do_time, PGtimeBL = toc; fprintf('PGtimeBL=%d\n',PGtimeBL); end
if do_time, tic; end
[sr2,arg0,arg1]=filterbankreassign(c_s2,tgrad,fgrad,a,cfreq1); 
if do_time, RAtimeBL = toc; fprintf('RAtimeBL=%d\n',RAtimeBL); end
figure(2); subplot(312); plotfilterbank(sr2,a,'fc',fs/2*cfreq1,'linabs');

if do_all
if do_time, tic; end
[tgrad,fgrad,c_s3]=filterbankphasegrad(f,g3,a,L); 
if do_time, PGtimeL = toc; fprintf('PGtimeL=%d\n',PGtimeL); end
if do_time, tic; end
[sr3,arg0,arg1]=filterbankreassign(c_s3,tgrad,fgrad,a,cfreq1);
if do_time, RAtimeL = toc; fprintf('RAtimeL=%d\n',RAtimeL); end 
figure(2); subplot(313); plotfilterbank(sr3,a,'fc',fs/2*cfreq1,'linabs');
end
% 
% clear all

catch
    test_failed = 1;
end

