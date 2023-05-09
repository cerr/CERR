%-*- texinfo -*-
%@deftypefn {Function} demo_filterbanksynchrosqueeze
%@verbatim
%DEMO_FILTERBANKSYNCHROSQUEEZE Filterbank synchrosqueezing and inversion
%
%   The demo shows that the synchrosqueezed filterbank representation can be 
%   directly used to reconstruct the original signal.
%   Since we do not work with a filterbank which forms a tight frame 
%   (its FILTERBANKRESPONSE is not constant) the direct reconstruction 
%   (mere summing all the channels) does not work well. We can fix that by
%   filtering (equalizing) the result by the inverse of the overall analysis 
%   filterbank frequency response.
%
%   Figure 1: ERBlet spectrogram (top) and synchrosqueezed ERBlet spectrogram (bottom)
%
%      The signal used is the first second from GSPI. Only the energy of
%      the coefficients is show. Both representations are in fact complex and
%      invertible.
%
%   Figure 2: Errors of the direct and the equalized reconstructions
%       
%      There is still a small DC offset of the signal obtained by the direct
%      summation.
%
%   References:
%     N. Holighaus, Z. Průša, and P. L. Soendergaard. Reassignment and
%     synchrosqueezing for general time-frequency filter banks, subsampling
%     and processing. Signal Processing, 125:1--8, 2016. [1]http ]
%     
%     References
%     
%     1. http://www.sciencedirect.com/science/article/pii/S0165168416000141
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/demos/demo_filterbanksynchrosqueeze.html}
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

% Get one second of gspi
Ls = 44100;
[f,fs] = gspi;
f = f(1:Ls);

% Create an UNIFORM filterbank
[g,a,fc] = erbfilters(fs,Ls,'uniform','M',400);

% We will not do no subsampling. 
% This is the main requirement for synchrosqueezing to work.
a = 1;

% Compute the time phase derivative and the coefficients
[tgrad,~,~,c] = filterbankphasegrad(f,g,a);

% Do the synchrosqueezing
cs = filterbanksynchrosqueeze(c,tgrad,cent_freqs(fs,fc));

% Plot spectrograms
figure(1);clf;
subplot(2,1,1);
plotfilterbank(c,a,fc,fs,60);
subplot(2,1,2);
plotfilterbank(cs,a,fc,fs,60);

% Reformat the coefficients to matrices
cmat = cell2mat(c.');
csmat = cell2mat(cs.');

% Compute the overall analysis filterbank response.
Frespall = sum(filterbankfreqz(g,a,Ls),2);

% The fiterbank is defined only for positive frequencies, we 
% sum the response with its involution
Frespfull = Frespall + involute(Frespall);

% The filterbank is not tight, so the direct reconstruction 
% will not give a good reconstruction.
% We do that anyway for comparison.
% 
% Just scale so that the response is around 1
C = mean(abs(Frespfull));
Frespfull = Frespfull/C;

% Direct reconstruction from the original coefficients 
fhat1  = 2*real(sum(cmat,2))/C;
% Direct reconstruction from the synchrosqueezed coefficents
fhat1s = 2*real(sum(csmat,2))/C;

% Reconstruction errors
err1 = norm(f-fhat1)/norm(f);
err1s = norm(f-fhat1s)/norm(f);

% We "equalize" the reconstruction by inverse of Frespfull
fhat2 = real(ifft(fft(fhat1)./Frespfull));
fhat2s = real(ifft(fft(fhat1s)./Frespfull));

% Compute errors
err2 = norm(f-fhat2)/norm(f);
err2s = norm(f-fhat2s)/norm(f);

% Plot errors for comparison
figure(2);clf;
title('Error of the reconstruction');
plot([f-fhat1s, f-fhat2s]);
legend({'notequalized','equalized'});

fprintf(['Direct reconstruction MSE:\n   From the coefficients: %e\n',...
         '   From the synchrosqueezed coefficients: %e\n'],err1,err1s);

fprintf(['Equalized reconstruction MSE:\n   From the coefficients: %e\n',...
         '   From the synchrosqueezed coefficients: %e\n'],err2,err2s);


