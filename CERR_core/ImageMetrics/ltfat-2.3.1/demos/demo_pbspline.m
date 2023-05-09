%-*- texinfo -*-
%@deftypefn {Function} demo_pbspline
%@verbatim
%DEMO_PBSPLINE  How to use PBSPLINE
%
%   This script illustrates various properties of the
%   PBSPLINE function.
%
%   Figure 1: Three first splines
%
%      This figure shows the three first splines (order 0,1 and 2)
%      and their dual windows.
%
%      Note that they are calculated for an even number of the parameter a,
%      meaning that they are not exactly splines, but a slightly smoother
%      construction, that still form a partition of unity.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/demos/demo_pbspline.html}
%@seealso{pbspline, middlepad}
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

disp('Type "help demo_pbspline" to see a description of how this demo works.');

% Setup parameters and length of signal.
% Note that it must hold that L=M*b=N*a for some integers
% b and N, and that a <= M

L=72;  % Length of signal.
a=6;   % Time shift.
M=9;   % Number of modulations.

% Calculate the frequency shift.
b=L/M;

% The following call creates a B-spline of order 2.
% The translates of a multiple of 'a' of this function
% creates a partition of unity.
% 'ntaps' contains the number of non-zero elements of g
[g,ntaps]=pbspline(L,2,a);

disp('');
disp('Length of the generated window:');
ntaps

% This DFT of g is real and whole point even
disp('');
disp('Norm of imaginary part. Should be close to zero.');
norm(imag(dft(g)))

disp('');
disp('Window is whole point even. Should be 1.');
isevenfunction(g)

% We can cut g to length ntap without loosing any information:
% Cut g
gcut=middlepad(g,ntaps);

disp('');
disp('Length of g after cutting.');
length(gcut)

% extend gcut again
gextend=middlepad(gcut,L);

% gextend is identical to g
disp('');
disp('difference between original g, and gextend.');
disp('Should be close to zero.');
norm(g-gextend)


% Plot the three first splines and their canonical dual windows:

% Calculate the splines.
g1=pbspline(L,0,a);
g2=pbspline(L,1,a);
g3=pbspline(L,2,a);

% Calculate their dual windows.
g1d=gabdual(g1,a,M);
g2d=gabdual(g2,a,M);
g3d=gabdual(g3,a,M);

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

figure(1);

xplot=(0:L-1).';

subplot(3,2,1);
plot(xplot,fftshift(g1),...
     xplot,circshift(fftshift(g1),a),...
     xplot,circshift(fftshift(g1),-a));
title('Zero order spline.');

subplot(3,2,2);
plot(xplot,fftshift(g1d));
title('Dual window.');

subplot(3,2,3);
plot(xplot,fftshift(g2),...
     xplot,circshift(fftshift(g2),a),...
     xplot,circshift(fftshift(g2),-a));
title('First order spline.');

subplot(3,2,4);
plot(xplot,fftshift(g2d));
title('Dual window.');

subplot(3,2,5);
plot(xplot,fftshift(g3),...
     xplot,circshift(fftshift(g3),a),...
     xplot,circshift(fftshift(g3),-a));
title('Second order spline.');

subplot(3,2,6);
plot(xplot,fftshift(g3d));
title('Dual window.');

