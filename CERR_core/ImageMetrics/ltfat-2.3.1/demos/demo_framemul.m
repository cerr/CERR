%-*- texinfo -*-
%@deftypefn {Function} demo_framemul
%@verbatim
%DEMO_FRAMEMUL  Time-frequency localization by a Gabor multiplier
%
%   This script creates several different time-frequency symbols
%   and demonstrate their effect on a random, real input signal.
%
%   Figure 1: Cut a circle in the TF-plane
%
%      This figure shows the symbol (top plot, only the positive frequencies are displayed),
%      the input random signal (bottom) and the output signal (middle).
%
%   Figure 2: Keep low frequencies (low-pass)
%
%      This figure shows the symbol (top plot, only the positive frequencies are displayed),
%      the input random signal (bottom) and the output signal (middle).
%
%   Figure 3: Keep middle frequencies (band-pass)
%
%      This figure shows the symbol (top plot, only the positive frequencies are displayed),
%      the input random signal (bottom) and the output signal (middle).
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/demos/demo_framemul.html}
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

disp('Type "help demo_framemul" to see a description of how this demo works.');

% Setup some suitable parameters for the Gabor system
L=480;
a=20;
M=24;

b=L/M;
N=L/a;

% Plotting initializations
t_axis = (0:(M-1))*a;
f_max = floor(N/2)-1;
f_range = 1:(f_max+1);
f_axis = f_range*b;

xlabel_angle = 7;
ylabel_angle = -11;

% Create a tight window, so it can be used for both analysis and
% synthesis.

% Frames framework equivalent g=gabtight(a,M,L);
F = frametight(frame('dgt','gauss',a,M));


% Create the random signal.
f=randn(L,1);

% ------- sharp cutoff operator ---------
% This cuts out a circle in the TF-plane. 
symbol1=zeros(M,N);

for m=0:M-1
  for n=0:N-1
    if (m-M/2)^2+(n-N/2)^2 <(M/4)^2
      symbol1(m+1,n+1)=1;
    end;
  end;
end;

% The symbol as defined by the above loops is centered such
% that it keeps the high frequencys. To obtain the low ones, we
% move the symbol along the first dimension:
symbol1=fftshift(symbol1,1);


% Do the actual filtering
% Frames framework equivalent to ff1=gabmul(f,symbol1,g,a);
ff1 = framemul(f,F,F,framenative2coef(F,symbol1));


% plotting
figure(1);

subplot(3,1,1);
mesh(t_axis,f_axis,symbol1(f_range,:));

if isoctave
  xlabel('Time');
  ylabel('Frequency');
else
  xlabel('Time','rotation',xlabel_angle);
  ylabel('Frequency','rotation',ylabel_angle);
end;

subplot(3,1,2);
plot(real(ff1));

subplot(3,1,3);
plot(f);


% ---- Tensor product symbol, keep low frequencies.
t1=pgauss(M);
t2=pgauss(N);

symbol2=fftshift(t1*t2',2);

% Do the actual filtering
% Frames framework equivalent to ff2=gabmul(f,symbol2,g,a);
ff2 = framemul(f,F,F,framenative2coef(F,symbol2));

figure(2);

subplot(3,1,1);
mesh(t_axis,f_axis,symbol2(f_range,:));

if isoctave
  xlabel('Time');
  ylabel('Frequency');
else
  xlabel('Time','rotation',xlabel_angle);
  ylabel('Frequency','rotation',ylabel_angle);
end;

subplot(3,1,2);
plot(real(ff2));

subplot(3,1,3);
plot(f);

% ----- Tensor product symbol, keeps middle frequencies.
t1=circshift(pgauss(M,.5),round(M/4))+circshift(pgauss(M,.5),round(3*M/4));
t2=pgauss(N);

symbol3=fftshift(t1*t2',2);

% Do the actual filtering
% Frames framework equivalent to ff3=gabmul(f,symbol3,g,a);
ff3 = framemul(f,F,F,framenative2coef(F,symbol3));

figure(3);

subplot(3,1,1);
mesh(t_axis,f_axis,symbol3(f_range,:));

if isoctave
  xlabel('Time');
  ylabel('Frequency');    
else    
  xlabel('Time','rotation',xlabel_angle);
  ylabel('Frequency','rotation',ylabel_angle);
end;

subplot(3,1,2);
plot(real(ff3));

subplot(3,1,3);
plot(f);

