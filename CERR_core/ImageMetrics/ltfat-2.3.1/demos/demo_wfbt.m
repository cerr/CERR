%-*- texinfo -*-
%@deftypefn {Function} demo_wfbt
%@verbatim
%DEMO_WFBT  Auditory filterbanks built using filterbank tree structures
%
%   This demo shows two specific constructions of wavelet filterbank trees
%   using several M-band filterbanks with possibly different M (making the
%   thee non-homogenous) in order to approximate auditory frequency bands 
%   and a musical scale respectively.  Both wavelet trees produce perfectly
%   reconstructable non-redundant representations. 
%
%   The constructions are the following:
%
%      1) Auditory filterbank, approximately dividing the frequency band 
%         into intervals reminisent of the bask scale.
%
%      2) Musical filterbank, approximately dividing the freq. band into
%         intervals reminicent of the well-tempered musical scale.
%         
%   Shapes of the trees were taken from fig. 8 and fig. 9 from the refernece.
%   Sampling frequency of the test signal is 48kHz as used in the article.
%
%   Figure 1: Frequency responses of the auditory filterbank.
%
%      Both axes are in logarithmic scale.
%   
%   Figure 2: TF plot of the test signal using the auditory filterbank.
% 
%   Figure 3: Frequency responses of the musical filterbank.
%
%      Both axes are in logarithmic scale.
%   
%   Figure 4: TF plot of the test signal using the musical filterbank.
%
%   References:
%     F. Kurth and M. Clausen. Filter bank tree and M-band wavelet packet
%     algorithms in audio signal processing. Signal Processing, IEEE
%     Transactions on, 47(2):549--554, Feb 1999.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/demos/demo_wfbt.html}
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

% Load a test signal and resample it to 48 kHz since such sampling
% rate is assumed in the reference.
f = resample(greasy,3,1);
fs = 48000;

% Bark-like filterbank tree
% Creating tree depicted in Figure 8 in the reference. 
w = wfbtinit({'cmband3',1});
w = wfbtput(1,0,'cmband6',w);
w = wfbtput(1,1,'cmband3',w);
w = wfbtput(2,0:1,'cmband5',w);
w = wfbtput(2,2:3,'cmband2',w);

% Convert to filterbank
[g,a] = wfbt2filterbank(w);

% Plot frequency responses
figure(1);
filterbankfreqz(g,a,2*2048,'plot','fs',fs,'dynrange',30,'posfreq','flog');

% Do the transform
[c,info] = wfbt(f,w);
disp('The reconstruction should be close to zero:')
norm(f-iwfbt(c,info))

figure(2);
plotwavelets(c,info,fs,'dynrange',60);

% Well-tempered musical scale filterbank tree
% Creating tree depicted in Figure 9 in the reference. 
w2 = wfbtinit({'cmband4',1});
w2 = wfbtput(1,0:1,'cmband6',w2);
w2 = wfbtput(2,0:1,'cmband4',w2);
w2 = wfbtput(3,1:4,'cmband4',w2);

% Convert to filterbank
[g2,a2] = wfbt2filterbank(w2);
figure(3);
filterbankfreqz(g2,a2,2*2048,'plot','fs',fs,'dynrange',30,'posfreq','flog');


[c2,info2] = wfbt(f,w2);
disp('The reconstruction should be close to zero:')
norm(f-iwfbt(c2,info2))


figure(4);
plotwavelets(c2,info2,fs,'dynrange',60);




