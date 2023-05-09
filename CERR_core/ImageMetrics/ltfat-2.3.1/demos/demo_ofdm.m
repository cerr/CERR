%-*- texinfo -*-
%@deftypefn {Function} demo_ofdm
%@verbatim
%DEMO_OFDM  Demo of Gabor systems used for OFDM
%
%   This demo shows how to use a Gabor Riesz basis for OFDM.
%
%   We want to transmit a signal consisting of 0's and 1's through a
%   noisy communication channel. This is accomplished in the following
%   steps in the demo:
%
%     1) Convert this digital signal into complex valued coefficients by
%        QAM modulation.
%
%     2) Construct the signal to be transmitted by an inverse Gabor
%        transform of the complex coefficients
%
%     3) "Transmit" the signal by applying a spreading operator to the
%        signal and adding white noise
%
%     4) Convert the received signal into noisy coefficients by a Gabor
%        transform
%
%     5) Convert the noisy coefficients into bits by inverse QAM.
%
%   Some simplifications used to make this demo simple:
%
%      We assume that the whole spectrum is available for transmission.
%
%      The window and its dual have full length support. This is not
%       practical, because all data would have to be processed at once.
%       Instead, an FIR should be used, with both the window and its dual
%       having a short length.
%
%      The window is periodic. The data at the very end interferes with
%       the data at the very beginning. A simple way to solve this is to
%       transmit zeros at the beginning and at the end, to flush the system
%       properly.
%
%   Figure 1: Received coefficients.
%
%      This figure shows the distribution in the complex plane of the 
%      received coefficients. If the channel was perfect, all the points
%      should appear at the complex roots of unity (1,i,-1 and -i). This
%      demo is random, so everytime it is run it produces a new plot, and
%      the error rate may vary.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/demos/demo_ofdm.html}
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

disp('Type "help demo_ofdm" to see a description of how this demo works.');
%% ----------- setup of signal and transmission system --------------------

% Number of channels to use
M=20;

% Time-distance between succesive transmission. This must be
% larger than M, otherwise the symbols will interfere.
a=24;

% Number of bits to transmit, must be divisable by 2*M
nbits=16000;

% Length (in samples) of transmitted signal.
L=nbits/(2*M)*a;

% We choose an orthonormal window.
g=gabtight(a,M,L);

%% ----------- Setup of communication channel ---------------------------

% Larger means more random
howrandom=.3;  

% Rate of decay away from (1,1). Larger means smaller spread (faster decay).
spreaddecay=1.2; 

% Noiselevel for the channel.
noiselevel=0.05;

% Define the symbol of the spreading operator
symbol=sparse(L,L);
for ii=1:3
  for jj=1:3
    symbol(ii,jj)=(1-abs(randn(1)*howrandom))*exp(-(ii+jj-1)*spreaddecay);
  end;
end;

% Make the symbol conserve real signals.
symbol=(symbol+involute(symbol))/2;

% Make sure that energy is conserved
symbol=symbol/sum(abs(symbol(:)));

%% ------------ Convert input data into analog signal -------------------

% Create a random stream of bits.
inputdata=round(rand(nbits,1));

% QAM modulate it
transmitdata=qam4(inputdata);

% Create the signal to be tranmitted
f=idgt(reshape(transmitdata,M,[]),g,a);

% --- transmission of signal - influence of the channel ----------

% Apply the underspread operator.
f=spreadop(f,symbol);

% add white noise.
noise = ((randn(size(f))-.5)+i*(randn(size(f))-.5));
f=f+noise*noiselevel/norm(noise)*norm(f);

% --- reconstruction of received signal ------------------------

% Obtain the noisy coefficients from the transmitted signal
receivedcoefficients = dgt(f,g,a,M);

% Convert the analog signal to the digital coefficients by inverse QAM
receivedbits=iqam4(receivedcoefficients(:));

%% --- visualization and print output -------------------------

% Plot the coefficients in the complex plane.
figure(1);
plot(receivedcoefficients(:),'.');
axis([-1 1 -1 1]);

% Test for errors.

disp(' ');
disp('Number of faulty bits:');
faulty=sum(abs(receivedbits-inputdata))

disp(' ');
disp('Error rate:');
faulty/nbits

