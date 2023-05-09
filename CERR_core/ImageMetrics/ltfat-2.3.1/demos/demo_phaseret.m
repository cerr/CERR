%-*- texinfo -*-
%@deftypefn {Function} demo_phaseret
%@verbatim
%DEMO_PHASERET Phase retrieval and phase difference
%
%   This demo demonstrates iterative reconstruction of a spectrogram and
%   the phase difference.
%
%   Figure 1: Original spectrogram
%
%      This figure shows the target spectrogram of an excerpt of the gspi
%      signal
%
%   Figure 2: Phase difference
%
%      This figure shows a difference between the original phase and the 
%      reconstructed using 100 iterations of a Fast Griffin-Lim algorithm.
%      Note: The figure in the LTFAT 2.0 paper differs slightly because it
%      is genarated using 1000 iterations.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/demos/demo_phaseret.html}
%@seealso{frsynabs, plotframe}
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

% Here the number of iterations is set to 100 to speedup the execution
maxit = 100;

[f,fs]=gspi;
f=f(10001:100000);
g='gauss';
a=100; M=1000;
F = frame('dgtreal',g,a,M);
c = frana(F,f);

% Spectrogram values
s=abs(c).^2;
% Original phase
theta=angle(c);

% Do the reconstruction using the magnitude only
r = frsynabs(F,sqrt(s),'fgriflim','maxit',maxit);

% Re-analyse using the original frame
c_r = frana(F,r);

% Obtain phase of the re-analysis
s_r = abs(c_r).^2;

theta_r=angle(c_r);

d1=abs(theta-theta_r);
d2=2*pi-d1;
anglediff=min(d1,d2);

% Plot the original spectrogram
figure(1);
plotframe(F,c,fs,'dynrange',50);

% Plot the phase difference
figure(2);
anglediff(abs(c)<10^(-50/20)) = 0;
plotframe(F,anglediff,fs,'lin');



