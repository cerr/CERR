%-*- texinfo -*-
%@deftypefn {Function} demo_nsdgt
%@verbatim
%DEMO_NSDGT  Non-stationary Gabor transform demo
%
%   This script sets up a non-stationary Gabor frame with the specified
%   parameters, computes windows and corresponding canonical dual windows
%   and a test signal, and plots the windows and the energy of the 
%   coefficients.
%
%   Figure 1: Windows + dual windows
% 
%      This figure shows the window functions used and the corresponding
%      canonical dual windows. 
%
%   Figure 2: Spectrogram (absolute value of coefficients in dB)
%
%      This figure shows a (colour-coded) image of the nsdgt coefficient
%      modulus. 
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/demos/demo_nsdgt.html}
%@seealso{nsdgt, insdgt, nsgabdual}
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

disp(['Type "help demo_nsdgt" to see a description of how this example',...
  ' works.']);

% Setup parameters and length of signal.

Ls=965; % Length of signal.

N=16; % Number of time positions

% Define a set of windows with length growing linearly. The step beetween
% to consecutive windows also grows linearly.

M=round(linspace(40,200,N)');
a=cumsum(round(M/2));
a=a-a(1);

a_new=round(M/2);

g={};
for ii=1:length(M)
    g{ii}=firwin('hann',M(ii));
end

% Compute corresponding dual windows
gd=nsgabdual(g,a_new,M,Ls);

% Plot them
figure(1);
color = ['b', 'r'];
for ii = 1:length(a)
    subplot(2,1,1);
    hold on;
    plot(a(ii)-1-floor(M(ii)/2)+(1:M(ii)), fftshift(g{ii}),...
      color(rem(ii,2)+1));
    subplot(2,1,2);
    hold on;
    plot(a(ii)-1-floor(M(ii)/2)+(1:M(ii)), fftshift(gd{ii}),...
      color(rem(ii,2)+1));
end

subplot(2,1,1);
title('Analysis windows');
xlabel('Time index');
subplot(2,1,2);
title('Dual synthesis windows');
xlabel('Time index');

% Define a sinus test signal so it is periodic.
f=sin(2*pi*(289/Ls)*(0:Ls-1)');

% Calculate coefficients.
c=nsdgt(f,g,a_new,M);

% Plot corresponding spectrogram
figure(2);
plotnsdgt(c,a,'dynrange',100);
title('Spectrogram of test signal')

% Test reconstruction
f_r=insdgt(c,gd,a_new,Ls);

% Print relative error of reconstruction.
rec_err = norm(f-f_r)/norm(f);

fprintf(['Relative error of reconstruction (should be close to zero.):'...
    '   %e \n'],rec_err);

