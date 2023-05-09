%-*- texinfo -*-
%@deftypefn {Function} demo_dgt
%@verbatim
%DEMO_DGT  Basic introduction to DGT analysis/synthesis
%
%   This demo shows how to compute Gabor coefficients of a signal.
%
%   Figure 1: Spectrogram of the 'bat' signal.
%
%      The figure shows a spectrogram of the 'bat' signal. The
%      coefficients are shown on a linear scale.
%
%   Figure 2: Gabor coefficients of the 'bat' signal.
%
%      The figure show a set of Gabor coefficients for the 'bat' signal,
%      computed using a DGT with a Gaussian window. The coefficients
%      contains all the information to reconstruct the signal, even though
%      there a far fewer coefficients than the spectrogram contains.
%
%   Figure 3: Real-valued Gabor analysis
%
%      This figure shows only the coefficients for the positive
%      frequencies. As the signal is real-value, these coefficients
%      contain all the necessary information. Compare to the shape of the
%      spectrogram shown on Figure 1.
%
%   Figure 4: DGT coefficients on a spectrogram
%
%      This figure shows how the coefficients from DGTREAL can be picked
%      from the coefficients computed by a full Short-time Fourier
%      transform, as visualized by a spectrogram.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/demos/demo_dgt.html}
%@seealso{sgram, dgt, dgtreal}
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

disp('Type "help demo_dgt" to see a description of how this demo works.');

% Load a test signal
f=bat;

% sampling rate of the test signal, only important for plotting
fs=143000;

% Length of signal
Ls=length(f);

disp(' ');
disp('------ Spectrogram analysis -----------------------------------');

figure(1);
c_sgram=sgram(f,fs,'lin');
title('Spectrogram of the bat test signal.');


% Number of coefficients in the Spectrogram
no_sgram=numel(c_sgram);

disp(' ');
disp('The spectrogram is highly redundant.');
fprintf('No. of coefficients in the signal:       %i\n',Ls);
fprintf('No. of coefficients in the spectrogram:  %i\n',no_sgram);
fprintf('Redundacy of the spectrogram:            %f\n',no_sgram/Ls);

% WARNING: In the above code, the spectrogram routine SGRAM returns the
% coefficients use to plot the image. These coefficients are ONLY
% intended to be used by post-processing image tools, and in this
% example, the are only used to illustrate the redundancy of the
% spectogram. Numerical Gabor signal analysis and synthesis should ALWAYS
% be done using the DGT, IDGT, DGTREAL and IDGTREAL functions, see the
% following sections of this example.

disp(' ');
disp('---- Simple Gabor analysis using a standard Gaussian window. ----');

disp('Setup parameters for a Discrete Gabor Transform.')
disp('Time shift:')
a=20

disp('Number of frequency channels.');
M=40

disp(' ');
disp('Note that it must hold that L = M*b = N*a for some integers b, N and L,');
disp('and that a<M. L is the transform length, and the DGT will choose the');
disp('smallest possible value of L that is larger or equal to the length of the');
disp('signal. Choosing a<M makes the transform redundant, otherwise the');
disp('transform will be lossy, and reconstruction will not be possible.');

% Simple DGT using a standard Gaussian window.
c=dgt(f,'gauss',a,M);

disp('Number of time shifts in transform:')
N = size(c,2);

disp('Length of transform:')
L = N*a


figure(2);
plotdgt(c,a,'linsq');
title('Gabor coefficients.');

disp(' ');
disp(['The redundancy of the Gabor transform can be reduced without loosing ' ...
      'information.']);
fprintf('No. of coefficients in the signal:       %i\n',Ls);
fprintf('No. of output coefficients from the DGT: %i\n',numel(c));
fprintf('Redundacy of the DGT (in this case)      %f\n',numel(c)/Ls);

disp(' ');
disp('---- Real valued Gabor analysis. ----');

% Figure 1 and Figure 2 looks quite different, because Figure 2 also
% displays the coefficients for the n

% Simple real valued DGT using a standard Gaussian window.
c_real=dgtreal(f,'gauss',a,M);

figure(3);
plotdgtreal(c_real,a,M,'linsq');
title('Positive-frequency DGT coefficients (DGTREAL).');

figure(4);
b=L/M;
[X,Y]=meshgrid(1:a:L+a,1:b:L/2+b);

hold on;
imagesc(c_sgram);
plot([X(:),X(:)]',[Y(:),Y(:)]','wo','Linewidth',1);
axis('xy','image');
hold off;
title('Placement of the DGTREAL coefficients on the spectrogram.');

disp(' ');
disp('---- Perfect reconstruction. ----');

% Reconstruction from the full DGT coefficients
r      = idgt(c,'gaussdual',a);

% Reconstruction from the DGTREAL coefficients
% The parameter M cannot be deduced from the size of the coefficient
% array c_real, so it is an explicit input parameter.
r_real = idgtreal(c_real,'gaussdual',a,M);

fprintf('Reconstruction error using IDGT:      %e\n',norm(f-r));
fprintf('Reconstruction error using IDGTREAL:  %e\n',norm(f-r_real));

