%-*- texinfo -*-
%@deftypefn {Function} demo_filterbanks
%@verbatim
%DEMO_FILTERBANKS  CQT, ERBLET and AUDLET filterbanks
%
%   This demo shows CQT (Constant Quality Transform), ERBLET (Equivalent
%   Rectangular Bandwidth -let transform), and AUDLET (Auditory -let) 
%   representations acting as filterbanks  with high and low redundancies.
%   Note that ERBLET and AUDLET are similar concepts. The main difference
%   is that ERBlet uses only the perceptual ERB scale while AUDlet allows
%   for various perceptual scales like Bark or Mel scales. In short,
%   ERBFILTERS is a wrapper of AUDFILTERS for the ERB scale. 
%   Filterbanks are build such that the painless condition is always satisfied.
%   Real input signal and filters covering only the positive frequency range 
%   are used. The redundancy is calculated as a ratio of the number of (complex) 
%   coefficients and the input length times two to account for the storage
%   requirements of complex numbers.
%
%      The high redundancy representation uses 'uniform' subsampling i.e.
%       all channels are subsampled with the same subsampling factor which
%       is the lowest from the filters according to the painless condition
%       rounded towards zero.
%
%      The low redundancy representation uses 'fractional' subsampling
%       which results in the least redundant representation still
%       satisfying the painless condition. Actual time positions of atoms 
%       can be non-integer, hence the word fractional.
%
%   Figure 1: ERBLET representations
%
%      The high-redundany plot (top) consists of 400 channels (~9 filters 
%      per ERB) and low-redundany plot (bottom) consists of 44 channels 
%      (1 filter per ERB).
%
%   Figure 2: CQT representations
%
%      Both representations consist of 280 channels (32 channels per octave,
%      frequency range 50Hz-20kHz). The high-redundany represention is on 
%      the top and the low-redundancy repr. is on the bottom.
% 
%   Figure 3: AUDLET representations
%
%      The first representation consists of 72 channels BARKlet FB (3 filters
%      per Bark in the frequency range 100Hz-16kHz using fractional subsampling.
%      The second representation consists of 40 channels MELlet FB using
%      uniform subsampling and triangular windows.
%
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/demos/demo_filterbanks.html}
%@seealso{audfilters, erbfilters, cqtfilters}
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

% Read the test signal and crop it to the range of interest
[f,fs]=gspi;
f=f(10001:100000);
dr=50;

figure(1);
subplot(2,1,1);

% Create the ERB filterbank using 400 filters linearly spaced in the 
% ERB scale and using uniform subsampling.
[g,a,fc]=erbfilters(fs,numel(f),'M',400,'uniform');

% Compute the filterbank response
c1=filterbank(f,g,a);

% Compute redundancy
erb1_redundancy = 2*sum(1./a);

% Plot the representation
plotfilterbank(c1,a,fc,fs,dr,'audtick');
title('ERBLET representations')

subplot(2,1,2);

% Create the ERB filterbank using 44 filters linearly spaced in the 
% ERB scale and using fractional subsampling.
[g,a,fc]=erbfilters(fs,numel(f),'fractional');

% Compute the filterbank response
c2=filterbank(f,g,a);

% Compute redundancy
erb2_redundancy = 2*sum(a(:,2)./a(:,1));

% Plot the representation
plotfilterbank(c2,a,fc,fs,dr,'audtick');

fprintf('ERBLET high redundancy %.2f, low redundany %.2f.\n',...
         erb1_redundancy,erb2_redundancy);

figure(2);
subplot(2,1,1);

% Create the CQT filterbank using 32 channels per octave in frequency 
% range 50Hz-20kHz using uniform subsampling.
[g,a,fc] = cqtfilters(fs,50,20000,32,numel(f),'uniform');

% Compute the filterbank response
c3=filterbank(f,g,a);

% Compute redundancy
cqt1_redundancy = 2*sum(1./a);

% Plot the representation
plotfilterbank(c3,a,fc,fs,'dynrange',dr);
title('CQT representations')

subplot(2,1,2);

% Create the CQT filterbank using 32 channels per octave in frequency 
% range 50Hz-20kHz using fractional subsampling.
[g,a,fc] = cqtfilters(fs,50,20000,32,numel(f),'fractional');

% Compute the filterbank response
c4=filterbank(f,g,a);

% Compute redundancy
cqt2_redundancy = 2*sum(a(:,2)./a(:,1));

% Plot the representation
plotfilterbank(c4,a,fc,fs,'dynrange',dr);

fprintf('CQT high redundancy %.2f, low redundany %.2f.\n',...
        cqt1_redundancy,cqt2_redundancy);
    
% Finally two settings of AUDFILTERS are illustrated, namely an analysis on
% the Bark scale (top) and one on the Mel scale using triangular windows (bottom).

figure(3);
subplot(2,1,1);

% Create a Barklet FB with 3 filters per Bark in the
% frequency range 100Hz-16kHz using fractional subsampling.
[g,a,fc]=audfilters(fs,numel(f),100,16000,'bark','fractional','spacing',1/3);

% Compute the filterbank response
c5=filterbank(f,{'realdual',g},a);

% Compute redundancy
bark_redundancy = 2*sum(a(:,2)./a(:,1));

% Plot the representation
plotfilterbank(c5,a,fc,fs,dr,'audtick');
title('AUDLET representations: Bark scale (top) and Mel scale (bottom)')

fprintf('BARKLET redundancy %.2f\n',bark_redundancy);

subplot(2,1,2);
% Create a MELlet FB with 40 filters and a triangular window using 
% uniform subsampling.
[g,a,fc]=audfilters(fs,numel(f),'mel','uniform','M',40,'tria');

% Compute the filterbank response
c6=filterbank(f,{'realdual',g},a);

% Compute redundancy
mel_redundancy = 2*sum(a.^-1);

% Plot the representation
plotfilterbank(c6,a,fc,fs,dr,'audtick');
title('MELlet representation')

fprintf('MELLET redundancy %.2f\n',mel_redundancy);



