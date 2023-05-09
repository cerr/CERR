%-*- texinfo -*-
%@deftypefn {Function} demo_gabfir
%@verbatim
%DEMO_GABFIR  Working with FIR windows
%
%   This demo demonstrates how to work with FIR windows in Gabor systems.
%
%   FIR windows are the windows traditionally used in signal processing.
%   They are short, much shorter than the signal, and this is used to make
%   effecient algorithms. They are also the only choice for applications
%   involving streaming data.
%
%   It is very easy to compute a spectrogram or Gabor coefficients using a
%   FIR window. The hard part is reconstruction, because both the window and
%   the dual window used for reconstruction must be FIR, and this is hard
%   to obtain, if the window is longer than the number of channels.
%
%   This demo demonstrates two methods:
%
%     1) Using a Gabor frame with a simple structure, for which dual/tight
%        FIR windows are easy to construct. This is a very common
%        technique in traditional signal processing, but it limits the
%        choice of windows and lattice parameters.
%
%     2) Cutting a canonical dual/tight window. We compute the canonical
%        dual window of the analysis window, and cut away the parts that
%        are close to zero. This will work for any analysis window and
%        any lattice constant, but the reconstruction obtained is not
%        perfect.
%
%   Figure 1: Hanning FIR window
%
%      This figure shows the a Hanning window in the time domain and its
%      magnitude response.
%
%   Figure 2: Kaiser-Bessel FIR window
%
%      This figure shows a Kaiser Bessel window and its magnitude response,
%      and the same two plots for the canonical dual of the window.
%
%   Figure 3: Gaussian FIR window for low redundancy
%
%      This figure shows a truncated Gaussian window and its magnitude
%      response. The same two plots are show for the truncated canonical
%      dual window.
%
%   Figure 4: Almost tight Gaussian FIR window
%
%      This figure shows a tight Gaussian window that has been truncated
%      and its magnitude response.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/demos/demo_gabfir.html}
%@seealso{firwin, firkaiser, gabdual}
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

% -------- first part: Analytically known FIR window ----------------- 

% The lattice constants to use.
a=16;
M=2*a;

% When working with FIR windows, some routines (gabdualnorm, magresp)
% require a transform length. Strictly speaking, this should be infinity,
% but this is not possible in the current implementation. Choosing an
% LLong that is some high multiple of M provides a very good approximation
% of the correct result.
LLong=M*16;

% Compute the iterated sine window. This window is a tight window when used
% with a Gabor system where the number of channels is larger than or
% equal to the length of the window.
g=gabwin('itersine',a,M);

disp('');
disp('Reconstruction error using itersine window, should be close to zero:');
gabdualnorm(g,g,a,M,LLong)

figure(1);

% Plot the window in the time-domain.
subplot(2,1,1);
plot(fftshift(g));
title('itersine FIR window.');

% Plot the magnitude response of the window (the frequency representation of
% the window on a dB scale).
subplot(2,1,2);
magresp(g,'fir','dynrange',100);
title('Magnitude response of itersine window.');

% -------- second part: True, short FIR window -------------------------

% If the length of the window is less than or equal to the number of
% channels M, then the canonical dual and tight windows will have the
% same support. This case is explicitly supported by gabdual

% Set up a nice Kaiser-Bessel window.
g=firkaiser(M,3.2,'energy');

% Compute the canonical dual window
gd=gabdual(g,a,M);

disp('');
disp('Reconstruction error canonical dual of Kaiser window, should be close to zero:');
gabdualnorm(g,gd,a,M)

figure(2);

% Plot the window in the time-domain.
subplot(2,2,1);
plot(fftshift(g));
title('Kaiser window.');

% Plot the magnitude response of the window (the frequency representation of
% the window on a dB scale).
subplot(2,2,2);
magresp(g,'fir','dynrange',100);
title('Magnitude response of Kaiser window.');

% Plot the window in the time-domain.
subplot(2,2,3);
plot(fftshift(gd));
title('Dual of Kaiser window.');

% Plot the magnitude response of the window (the frequency representation of
% the window on a dB scale).
subplot(2,2,4);
magresp(gd,'fir','dynrange',100);
title('Magnitude response of dual Kaiser window.');


% -------- Third part, cutting a LONG window --------------

% We can now work with any lattice constants and lower redundancies.
a=12;
M=18;

% LLong plays the same role as in the first part. It must be a multiple of
% both 'a' and M.
LLong=M*a*16;

% Construct an LONG Gaussian window with optimal time/frequency resolution.
glong=pgauss(LLong,a*M/LLong);

% Cut it to a FIR window, preserving the WPE symmetry.
% The length must be a multiple of M.
gfir=long2fir(glong,2*M,'wp');

% Extend the cutted window, and compute the dual window of this.
gfirextend=fir2long(gfir,LLong);
gd_long=gabdual(gfirextend,a,M);

% Cut it, preserving the WPE symmetry
gd_fir=long2fir(gd_long,6*M,'wp');

% Compute the reconstruction error
disp('');
disp('Reconstruction error using cutted dual window.');
recerr = gabdualnorm(gfir,gd_fir,a,M,LLong)

disp('');
disp('or expressed in dB:');
10*log10(recerr)

figure(3);

% Plot the window in the time-domain.
subplot(2,2,1);
plot(fftshift(gfir));
title('Gaussian FIR window.');

% Plot the magnitude response of the window (the frequency representation of
% the window on a dB scale).
subplot(2,2,2);
magresp(gfir,'fir','dynrange',100);
title('Magnitude response of FIR Gaussian.')

% Plot the window in the time-domain.
subplot(2,2,3);
plot(fftshift(gd_fir));
title('Dual of Gaussian FIR window.');

% Plot the magnitude response of the window (the frequency representation of
% the window on a dB scale).
subplot(2,2,4);
magresp(gd_fir,'fir','dynrange',100);
title('Magnitude response.');

% ----- Fourth part, cutting a tight LONG window --------------

% We reuse all the parameters of the previous demo.

% Get a tight window.
gt_long = gabtight(a,M,LLong);

% Cut it
gt_fir = long2fir(gt_long,6*M);

% Compute the reconstruction error
disp('');
disp('Reconstruction error using cutted tight window.');
recerr = gabdualnorm(gt_fir,gt_fir,a,M,LLong)

disp('');
disp('or expressed in dB:');
10*log10(recerr)

figure(4);

% Plot the window in the time-domain.
subplot(2,1,1);
plot(fftshift(gt_fir));
title('Almost tight FIR window.');

% Plot the magnitude response of the window (the frequency representation of
% the window on a dB scale).
subplot(2,1,2);
magresp(gt_fir,'fir','dynrange',100);
title('Magnitude response.');

