function ggd = pgrpdelay(g,L)
%-*- texinfo -*-
%@deftypefn {Function} pgrpdelay
%@verbatim
%PGRPDELAY Group delay of a filter with periodic boundaries
%   Usage:  ggd = pgrpdelay(g,L);
%
%   PGRPDELAY(g,L) computes group delay of filter g as a negative
%   derivative of the phase frequency response of filter g assuming
%   periodic (cyclic) boundaries i.e. the delay may be a negative number.
%   The derivative is calculated using the second order centered difference
%   approximation. 
%   The resulting group delay is in samples.
%
%   Example:
%   --------
%
%   The following example shows a group delay of causal, moving average
%   6tap FIR filter and it's magnitude frequency response for comparison.
%   The dips in the group delay correspond to places where modulus of the 
%   frequency response falls to zero.:
%
%      g = struct(struct('h',ones(6,1),'offset',0)); 
%      L = 512;
%      figure(1);
%      subplot(2,1,1);
%      plot(-L/2+1:L/2,fftshift(pgrpdelay(g,512)));
%      axis tight;ylim([0,4]);
%
%      subplot(2,1,2);
%      magresp(g,L,'nf');
%      
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/sigproc/pgrpdelay.html}
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


g = comp_fourierwindow(g,L,upper(mfilename));

H = comp_transferfunction(g,L);
Harg = angle(H);

% Forward approximation
tgrad_1 = Harg-circshift(Harg,-1);
tgrad_1 = tgrad_1 - 2*pi*round(tgrad_1/(2*pi));
% Backward approximation
tgrad_2 = circshift(Harg,1)-Harg;
tgrad_2 = tgrad_2 - 2*pi*round(tgrad_2/(2*pi));
% Average
ggd = (tgrad_1+tgrad_2)/2;
 
ggd = ggd/(2*pi)*L;


