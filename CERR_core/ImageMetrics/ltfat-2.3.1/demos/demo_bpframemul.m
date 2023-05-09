function demo_bpframemul 
%-*- texinfo -*-
%@deftypefn {Function} demo_bpframemul
%@verbatim
%DEMO_BPFRAMEMUL Frame multiplier acting as a time-varying bandpass filter
%
%   This demo demonstrates creation and effect of a Gabor multiplier. The
%   multiplier performs a time-varying bandpass filtering. The band-pass
%   filter with center frequency changing over time is explicitly created
%   but it is treated as a "black box" system. The symbol is identified by
%   "probing" the system with a white noise and dividing DGT of the output
%   by DGT of the input element-wise. The symbol is smoothed out by a 5x5
%   median filter.
%
%   Figure 1: The symbol of the multiplier.
%
%      This figure shows a symbol used in the Gabor multiplier.
%
%   Figure 2: Spectroram obtained by re-analysis of the test signal after applying the multiplier
%
%      This figure shows a spectrogram of the test signal after applying
%      the estimated Gabor multiplier.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/demos/demo_bpframemul.html}
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

% Sampling rate
fs = 44100;
% Input signal
f = gspi;
% Input length
L = numel(gspi);
% Initial center frequency of the band-pass filter 
fc = 5000;
% Modulation parameter for the center frequency of the band-pass filter
fvar = 4800;

% Gabor system parameters
win = {'tight','hann',882};
a = 200;
M = 1000;

% The bandpass filter chnges it's center frequency every 2*a samples
Lch = ceil(L/(2*a));

L = Lch*2*a;

% Center frequencies
l = 0:Lch-1;
l = l(:);
fcm = fc+fvar*sin(2*pi*l/Lch*10);
% Parameters of the bandpass filter
G = 40;
Q = 4;

Ha = zeros(Lch,3);
Hb = zeros(Lch,3);

% Design a IIR peaking filters ...
for l=1:Lch
 [Ha(l,:),Hb(l,:)]=parpeak(fcm(l),Q,G,fs);
end
% ...and make them band-pass filters.
Ha = Ha/10^(G/20);

% Create a white noise and divide it into input into blocks
ff = randn(L,1);
fblocks = reshape(ff,numel(ff)/Lch,Lch);

% Do a blockwise filtering of the white noise
y = blockfilter(fblocks,Ha,Hb);
% Obtain DGT of the output ...
cy = dgtreal(y(:),win,a,M);   
% And the input
cx = dgtreal(fblocks(:),win,a,M);  

% Create a symbol by a plain division of DGT of the output and the input.
% (This would be a deconvolution if Fourier multiplier was used)
symbol = cy./cx;
% Smooth out the extremes using a 2D 5x5 median filter
symbol = cmedfilt2(symbol,[5,5]);

% Plot the symbol
figure(1);
plotdgtreal(symbol,a,M,44100,'dynrange',50);

% Apply the symbol to a test signal
f = postpad(f,L);
c = dgtreal(f,win,a,M);
c = c.*symbol;
fhat = idgtreal(c,win,a,M,L);

% Plot spectrogram of the resulting signal
figure(2);
c = dgtreal(fhat,win,a,M);
plotdgtreal(c,a,M,44100,'dynrange',50);

% Filter the input signal by the time-varying band-pass filter directly
y = blockfilter(reshape(f,numel(f)/Lch,Lch),Ha,Hb);

% Export the signals (since we are in a function)
assignin('base','forig', f(:));
assignin('base','fmul', fhat(:));
assignin('base','fdir', y(:));

disp('The original signal can be played by typing: sound(forig,44100);');
disp(['The signal obtained by a direct filtering cen be played by ',... 
      '(this is what is approximated by the multiplier): sound(fdir,44100);']);
disp(['The signal obtained by applying the Gabor multiplier: sound(fmul,44100);']);


function y = blockfilter(fb,Ha,Hb)
%BLOCKFILTER Block filtering

y = zeros(size(fb));
Lch = size(fb,2);
Z = zeros(2,1);

for l=1:Lch
   [y(:,l),Z] = filter(Ha(l,:),Hb(l,:),fb(:,l),Z); 
end


function fo = cmedfilt2(f,d)
% CMEDFILT2 Complex 2D median filter

if any(rem(d,2)~=1)
    error('%s: Median filer window should have odd dimensions.',...
          upper(mfilename));
end

dims = size(f);

if dims(1) < d(1)
  error('%s: Median filer height is bigger than the image height.',...
        upper(mfilename)); 
end

if dims(2) < d(2)
  error('%s: Median filer width is bigger than the image width.',...
        upper(mfilename)); 
end

fo = f;

whalf = floor(d(2)/2);
hhalf = floor(d(1)/2);

% Safely inside of the image
% The border values are taken from the input 
for ii=(1+hhalf):(dims(1)-hhalf)
   for jj=(1+whalf):(dims(2)-whalf)
       neigh = sort(reshape(f(ii-hhalf:ii+hhalf,jj-whalf:jj+whalf),[],1));
       fo(ii,jj) = neigh(ceil(end/2));
   end
end

% Top rows
for ii=1:hhalf
   for jj=(1+whalf):(dims(2)-whalf)
       neigh = sort(reshape(f(1:ii+hhalf,jj-whalf:jj+whalf),[],1));
       fo(ii,jj) = neigh(ceil(end/2));
   end
end

% Top bottom rows
for ii=1:hhalf
   for jj=(1+whalf):(dims(2)-whalf)
       neigh = sort(reshape(f(end+1-(ii+hhalf):end,jj-whalf:jj+whalf),[],1));
       fo(end+1-ii,jj) = neigh(ceil(end/2));
   end
end

% The leftmost and rightmost collumns are not processed...

function [Ha,Hb]=parpeak(fc,Q,G,Fs)
% PARLSF Parametric Peaking filter
%   Input parameters:
%         fm    : Cut-off frequency
%         Q     : Filter quality. Q=fc/B, where B is filter bandwidth.
%         G     : Gain in dB
%         Fs    : Sampling frequency
%   Output parameters:
%         Ha    : Transfer function numerator coefficients.
%         Hb    : Transfer function denominator coefficients.
%
%  For details see Table 5.3 in the Zolzer: Digital Audio Signal 
%  Processing, 2nd Edition, ISBN: 978-0-470-99785-7
Ha = zeros(3,1);
Hb = zeros(3,1);
%b0
Hb(1) = 1;
Ha(1) = 1;
K = tan(pi*fc/Fs);
if G>0
   V0=10^(G/20);
   den = 1 + K/Q + K*K;
   % a0
   Ha(1) = (1+V0*K/Q+K*K)/den;
   % a1
   Ha(2) = 2*(K*K-1)/den;
   % a2
   Ha(3) = (1-V0*K/Q+K*K)/den;
   % b1
   Hb(2) = 2*(K*K-1)/den;
   % b2
   Hb(3) = (1-K/Q+K*K)/den;
elseif G<0
   V0=10^(-G/20);
   den = 1 + V0*K/Q + K*K;
   % a0
   Ha(1) = (1+K/Q+K*K)/den;
   % a1
   Ha(2) = 2*(K*K-1)/den;
   % a2
   Ha(3) = (1-K/Q+K*K)/den;
   % b1
   Hb(2) = 2*(K*K-1)/den;
   % b2
   Hb(3) = (1-V0*K/Q+K*K)/den;
end

