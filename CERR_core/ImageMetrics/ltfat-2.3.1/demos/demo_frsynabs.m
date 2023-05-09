%-*- texinfo -*-
%@deftypefn {Function} demo_frsynabs
%@verbatim
%DEMO_FRSYNABS  Construction of a signal with a given spectrogram
%
%   This demo demonstrates iterative reconstruction of a spectrogram.
%
%   Figure 1: Original spectrogram
%
%      This figure shows the target spectrogram
%
%   Figure 2: Linear reconstruction
%
%      This figure shows a spectrogram of a linear reconstruction of the
%      target spectrogram.
%
%   Figure 3: Iterative reconstruction using the Griffin-Lim method.
%
%      This figure shows a spectrogram of an iterative reconstruction of the
%      target spectrogram using the Griffin-Lim projection method.
%
%   Figure 4: Iterative reconstruction using the BFGS method.
%
%      This figure shows a spectrogram of an iterative reconstruction of the
%      target spectrogram using the BFGS method.
%
%   The BFGS method makes use of the minFunc software. To use the BFGS method, 
%   please install the minFunc software from:
%   http://www.cs.ubc.ca/~schmidtm/Software/minFunc.html.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/demos/demo_frsynabs.html}
%@seealso{isgramreal, isgram}
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

s=ltfattext;

figure(1);
imagesc(s);
colormap(gray);
axis('xy');

figure(2);
F = frame('dgtreal','gauss',8,800); 
scoef = framenative2coef(F,s);
sig_lin = frsyn(F,sqrt(scoef));
sgram(sig_lin,'dynrange',100);

figure(3);
sig_griflim = frsynabs(F,scoef);
sgram(sig_griflim,'dynrange',100);

figure(4);
sig_bfgs = frsynabs(F,scoef,'bfgs');
sgram(sig_bfgs,'dynrange',100);

