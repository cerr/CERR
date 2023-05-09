%-*- texinfo -*-
%@deftypefn {Function} demo_audiocompression
%@verbatim
%DEMO_AUDIOCOMPRESSION  Audio compression using N-term approx
%
%   This demos shows how to do audio compression using best N-term
%   approximation of an WMDCT transform.
%
%   The signal is transformed using an orthonormal WMDCT transform.
%   Then approximations with a fixed number N of coefficients are obtained
%   by:
%
%      Linear approximation: The N coefficients with lowest frequency
%       index are kept.
%
%      Non-linear approximation: The N largest coefficients (in
%       magnitude) are kept.
%
%   The corresponding approximated signal can be computed using IWMDCT.
%
%   Figure 1: Rate-distorition plot
%
%      The figure shows the output Signal to Noise Ratio (SNR) as a function
%      of the number of retained coefficients.
%
%   Note: The inverse WMDCT is not needed for computing computing
%   SNRs. Instead Parseval theorem states that the norm of a signal equals
%   the norm of the sequence of its WMDCT coefficients.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/demos/demo_audiocompression.html}
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

% Load audio signal
% Use the 'glockenspiel' signal.
sig=gspi;

% Shorten signal
L = 2^16;
sig = sig(1:L);

% Number of frequency channels
M = 1024;

% Number of time steps
N = L/M;

% Generate window
gamma = wilorth(M,L);

% Compute wmdct coefficients
c = wmdct(sig,gamma,M);


% L2 norm of signal
InputL2Norm = norm(c,'fro');

% Approximate, and compute SNR values
kmax = M;
kmin = kmax/32;             % 32 is an arbitrary choice
krange = kmin:32:(kmax-1);  % same remark

for k = krange,
    ResL2Norm_NL = norm(c-largestn(c,k*N),'fro');
    SNR_NL(k) = 20*log10(InputL2Norm/ResL2Norm_NL);
    ResL2Norm_L = norm(c(k:kmax,:),'fro');
    SNR_L(k) = 20*log10(InputL2Norm/ResL2Norm_L);
end


% Plot
figure(1);

set(gca,'fontsize',14);
plot(krange*N,SNR_NL(krange),'x-b',...
     krange*N,SNR_L(krange),'o-r');
axis tight; grid;
legend('Best N-term','Linear');
xlabel('Number of Samples', 'fontsize',14);
ylabel('SNR (dB)','fontsize',14);

