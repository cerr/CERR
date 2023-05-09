%-*- texinfo -*-
%@deftypefn {Function} demo_audscales
%@verbatim
%DEMO_AUDSCALES  Plot of the different auditory scales
%
%   This demos generates a simple figure that shows the behaviour of
%   the different audiory scales in the frequency range from 0 to 8000 Hz.
%
%   Figure 1: Auditory scales
%
%      The figure shows the behaviour of the audiory scales on a normalized
%      frequency plot.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/demos/demo_audscales.html}
%@seealso{freqtoaud, audtofreq, audspace, audspacebw}
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

disp(['Type "help demo_audscales" to see a description of how this ', ...
      'demo works.']);

% Set the limits
flow=0;
fhigh=8000;
plotpoints=50;

xrange=linspace(flow,fhigh,plotpoints);


figure(1);

types   = {'erb','bark','mel','erb83','mel1000'};
symbols = {'k-' ,'ro'  ,'gx' ,'b+'   ,'y*'};

hold on;
for ii=1:numel(types)
  curve = freqtoaud(xrange,types{ii});
  % Normalize the frequency to a maximum of 1.
  curve=curve/curve(end);
  plot(xrange,curve,symbols{ii});
end;
hold off;
legend(types{:},'Location','SouthEast');
xlabel('Frequency (Hz)');
ylabel('Auditory unit (normalized)');

