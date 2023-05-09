%-*- texinfo -*-
%@deftypefn {Function} demo_auditoryfilterbank
%@verbatim
%DEMO_AUDITORYFILTERBANK  Construct an auditory filterbank
%
%   In this file we construct a uniform filterbank using a the impulse
%   response of a 4th order gammatone for each channel. The center frequencies
%   are equidistantly spaced on an ERB-scale, and the width of the filter are
%   choosen to match the auditory filter bandwidth as determined by Moore.
%
%   Each channel is subsampled by a factor of 8 (a=8), and to generate a
%   nice plot, 4 channels per Erb has been used.
%
%   The filterbank covers only the positive frequencies, so we must use
%   FILTERBANKREALDUAL and FILTERBANKREALBOUNDS.
%
%   Figure 1: Classic spectrogram
%
%      A classic spectrogram of the spoken sentense. The dynamic range has
%      been set to 50 dB, to highlight the most important features.
%
%   Figure 2: Auditory filterbank representation
%
%      Auditory filterbank representation of the spoken sentense using
%      gammatone filters on an Erb scale.  The dynamic range has been set to
%      50 dB, to highlight the most important features.
%
%
%   References:
%     B. R. Glasberg and B. Moore. Derivation of auditory filter shapes from
%     notched-noise data. Hearing Research, 47(1-2):103, 1990.
%     
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/demos/demo_auditoryfilterbank.html}
%@seealso{freqtoaud, audfiltbw, gammatonefir, ufilterbank, filterbankrealdual}
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


% Use part of the 'cocktailparty' spoken sentense.
f=cocktailparty;
f=f(20001:80000,:);
fs=44100;
a=8;
channels_per_erb=2;
filterlength=5000;
dynrange_for_plotting=50;

% Determine minimal transform length
Ls=length(f);
L=ceil(filterlength/a)*a;

% Number of channels, slightly less than 1 ERB(Cambridge) per channel.
M=ceil(freqtoerb(fs/2)*channels_per_erb);

% Compute center frequencies.
fc=erbspace(0,fs/2,M);

%% --------------- display classic spectrogram -------------------
figure(1);
sgram(f,fs,dynrange_for_plotting);


%% ---------------  Gammatone filters ----------------------------

if 1

g_gam=gammatonefir(fc,fs,filterlength,'peakphase');

% In production code, it is not necessary to call 'filterbankrealbounds',
% this is just for veryfying the setup.
disp('Frame bound ratio for gammatone filterbank, should be close to 1 if the filters are choosen correctly.');
filterbankrealbounds(g_gam,a,L)

% Create reconstruction filters
gd_gam=filterbankrealdual(g_gam,a,L);

% Analysis transform
coef_gam=ufilterbank(f,g_gam,a);

% Synthesis transform
r_gam=2*real(ifilterbank(coef_gam,gd_gam,a,Ls));

disp('Relative error in reconstruction, should be close to zero.');
norm(f-r_gam)/norm(f)

figure(2);
plotfilterbank(coef_gam,a,fc,fs,dynrange_for_plotting,'audtick');

F  = frame('ufilterbankreal',g_gam,a,M);
c2 = frana(F,f); 
Ls=length(f);

[r_iter,relres,iter] = frsyniter(F,c2,Ls);
disp('Relative error in interative reconstruction, should be close to zero.');
norm(f-r_iter)/norm(f)

end;

