function [s,fs]=greasy()
%-*- texinfo -*-
%@deftypefn {Function} greasy
%@verbatim
%GREASY  Load the 'greasy' test signal
%   Usage:  s=greasy;
%
%   GREASY loads the 'greasy' signal. It is a recording of a woman
%   pronouncing the word "greasy".
%
%   The signal is 5880 samples long and recorded at 16 kHz with around 11
%   bits of effective quantization.
%
%   [sig,fs]=GREASY additionally returns the sampling frequency fs.
%
%   The signal has been scaled to not produce any clipping when
%   played. To get integer values use round(GREASY*2048).
%
%   The signal was obtained from Wavelab:
%   http://www-stat.stanford.edu/~wavelab/, it is a part of the first
%   sentence of the TIMIT speech corpus "She had your dark suit in greasy
%   wash water all year":
%   http://www.ldc.upenn.edu/Catalog/CatalogEntry.jsp?catalogId=LDC93S1.
%
%   Examples:
%   ---------
%
%   Plot of 'greasy' in the time-domain:
%
%     plot((1:5880)/16000,greasy);
%     xlabel('Time (seconds)');
%     ylabel('Amplitude');
%
%   Plot of 'greasy' in the frequency-domain:
%
%     plotfftreal(fftreal(greasy),16000,90);
%
%   Plot of 'greasy' in the time-frequency-domain:
%
%     sgram(greasy,16000,90);
%
%   References:
%     S. Mallat and Z. Zhang. Matching pursuits with time-frequency
%     dictionaries. IEEE Trans. Signal Process., 41(12):3397--3415, 1993.
%     
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/signals/greasy.html}
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

%   AUTHOR : Peter L. Soendergaard
%   TESTING: TEST_SIGNALS
  
if nargin>0
  error('This function does not take input arguments.')
end;

f=mfilename('fullpath');

s = wavload([f,'.wav']);
fs = 16000;


