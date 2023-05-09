%-*- texinfo -*-
%@deftypefn {Function} demo_gabmulappr
%@verbatim
%DEMO_GABMULAPPR Approximate a slowly time variant system by a Gabor multiplier
%   
%   This script construct a slowly time variant system and performs the 
%   best approximation by a Gabor multiplier with specified parameters
%   (a and L see below). Then it shows the action of the slowly time 
%   variant system (A) as well as of the best approximation of (A) by a 
%   Gabor multiplier (B) on a sinusoids and an exponential sweep.
%
%   Figure 1: Spectrogram of signals
%
%      The figure shows the spectogram of the output of the two systems applied on a 
%      sinusoid (left) and an exponential sweep.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/demos/demo_gabmulappr.html}
%@seealso{gabmulappr}
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

%   AUTHOR : Peter Balazs.
%   based on demo_gabmulappr.m 

disp('Type "help demo_gabmulappr" to see a description of how this demo works.');

% Setup parameters for the Gabor system and length of the signal
L=576; % Length of the signal
a=32;   % Time shift 
M=72;  % Number of modulations
fs=44100; % assumed sampling rate
SNRtv=63; % signal to noise ratio of change rate of time-variant system

% construction of slowly time variant system
% take an initial vector and multiply by random vector close to one
A = [];
c1=(1:L/2); c2=(L/2:-1:1); c=[c1 c2].^(-1); % weight of decay x^(-1)
A(1,:)=(rand(1,L)-0.5).*c;  % convolution kernel
Nlvl = exp(-SNRtv/10);
Slvl = 1-Nlvl;
for ii=2:L;
     A(ii,:)=(Slvl*circshift(A(ii-1,:),[0 1]))+(Nlvl*(rand(1,L)-0.5)); 
end;
A = A/norm(A)*0.99; % normalize matrix

% perform best approximation by gabor multiplier
sym=gabmulappr(A,a,M);

% creation of 3 different input signals (sinusoids)
x=2*pi*(0:L-1)/L.';
f1 = 1000; % frequency in Hz
s1=0.99*sin((fs/f1).*x);
% Ramp the signal to avoid distortions at the end, ramp are 5% of total
% length of the signal.
s1=rampsignal(s1,round(L*.05));

L1=ceil(L*0.9);
e1=0.99*expchirp(L1,500,fs/2*0.9,'fs',fs);
% Ramp signal as before.
e1=rampsignal(e1,round(L1*.05));
e1=[e1;zeros(L-L1,1)];

% application of the slowly time variant system
As1=A*s1';  
Ae1=A*e1;

% application of the Gabor multiplier
F = frametight(frame('dgt','gauss',a,M));
Gs1=framemul(s1(:),F,F,framenative2coef(F,sym)); 
Ge1=framemul(e1(:),F,F,framenative2coef(F,sym)); 


% Plotting the results
%% ------------- figure 1 ------------------------------------------

clim=[-40,13];
figure(1);
subplot(2,2,1);
sgram(real(As1),'tfr',10,'clim',clim,'nocolorbar'); 
title (sprintf('Spectogram of output signal: \n Time-variant system applied on sinusoid'),'Fontsize',14);
set(get(gca,'XLabel'),'Fontsize',14);
set(get(gca,'YLabel'),'Fontsize',14);

subplot(2,2,2);
sgram(real(Ae1),'tfr',10,'clim',clim,'nocolorbar'); 
title (sprintf('Spectogram of output signal: \n Time-variant system applied on exponential sweep'),'Fontsize',14);
set(get(gca,'XLabel'),'Fontsize',14);
set(get(gca,'YLabel'),'Fontsize',14);

subplot(2,2,3);
sgram(real(Gs1),'tfr',10,'clim',clim,'nocolorbar');
title (sprintf('Spectogram of output signal: \n Best approximation by Gabor multipliers applied on sinusoid'),'Fontsize',14);
set(get(gca,'XLabel'),'Fontsize',14);
set(get(gca,'YLabel'),'Fontsize',14);

subplot(2,2,4);
sgram(real(Ge1),'tfr',10,'clim',clim,'nocolorbar');
title (sprintf('Spectogram of output signal: \n Best approximation by Gabor multipliers applied on exponential sweep'),'Fontsize',14);
set(get(gca,'XLabel'),'Fontsize',14);
set(get(gca,'YLabel'),'Fontsize',14);

