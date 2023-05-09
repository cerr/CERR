%-*- texinfo -*-
%@deftypefn {Function} demo_pgauss
%@verbatim
%DEMO_PGAUSS  How to use PGAUSS
%
%   This script illustrates various properties of the Gaussian function.
%
%   Figure 1: Window+Dual+Tight
%
%      This figure shows an optimally centered Gaussian for a 
%      given Gabor system, its canonical dual and tight windows
%      and the DFTs of these windows.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/demos/demo_pgauss.html}
%@seealso{pgauss}
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

disp('Type "help demo_pgauss" to see a description of how this demo works.');

% A quick test: If the second input parameter to
% pgauss is not specified, the output will be
% invariant under an unitary DFT. Matlabs FFT is does not
% preserve the norm, so it must be scaled a bit.

L=128;
g=pgauss(L);

disp('');
disp('Test of DFT invariance: Should be close to zero.');
norm(g-dft(g))

% Setup parameters and length of signal.
% Note that it must hold that L=M*b=N*a for some integers
% b and N, and that a <= M
L=72;  % Length of signal.
a=6;   % Time shift.
M=9;   % Number of modulations.

% Calculate the frequency shift.
b=L/M;

% For this Gabor system, the optimally concentrated Gaussian
% is given by
g=pgauss(L,a/b);

% This is not invarient with respect to a DFT, but it is still
% real and whole point even
disp('');
disp('The function is WP even. The following should be 1.');
isevenfunction(g)

disp('Therefore, its DFT is real.');
disp('The norm of the imaginary part should be close to zero.');
norm(imag(dft(g)))

% Calculate the canonical dual.
gdual=gabdual(g,a,M);

% Calculate the canonical tight window.
gtight=gabtight(g,a,M);

% Plot them:

% Standard note on plotting:
%
% - All windows have real DFTs, but Matlab does not
%   always recoqnize this, so we have to filter away
%   the small imaginary part by calling REAL(...)
%
% - The windows are all centered around zero, but this
%   is not visually pleasing, so the window must be
%   shifted to the middle by an FFTSHIFT
%

gf_plot      = fftshift(real(dft(g)));
gdual_plot   = fftshift(gdual);
gdualf_plot  = fftshift(real(dft(gdual)));
gtight_plot  = fftshift(gtight);
gtightf_plot = fftshift(real(dft(gtight)));
figure(1);

subplot(3,2,1);
x=(1:L).';
plot(x,fftshift(g),'-',...
     x,circshift(fftshift(g),a),'-',...
     x,circshift(fftshift(g),-a),'-');
title('g=pgauss(72,6/8)');

subplot(3,2,2);
plot(gf_plot);
title('g, frequency domain');

subplot(3,2,3);
plot(gdual_plot);
title('Dual window of g');

subplot(3,2,4);
plot(gdualf_plot);
title('dual window, frequency domain');

subplot(3,2,5);
plot(gtight_plot);
title('Tight window generated from g');

subplot(3,2,6);
plot(gtightf_plot);
title('tight window, frequency domain');

