function [s,fs]=otoclick()
%-*- texinfo -*-
%@deftypefn {Function} otoclick
%@verbatim
%OTOCLICK  Load the 'otoclick' test signal
%   Usage:  s=otoclick;
%
%   OTOCLICK loads the 'otoclick' signal. The signal is a click-evoked
%   otoacoustic emission. It consists of two clear clicks followed by a
%   ringing. The ringing is the actual otoacoustic emission.
%
%   [sig,fs]=OTOCLICK additionally returns the sampling frequency fs.
%
%   It was measured by Sarah Verhulst at CAHR (Centre of Applied Hearing
%   Research) at Department of Eletrical Engineering, Technical University
%   of Denmark
%
%   The signal is 2210 samples long and sampled at 44.1 kHz.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/signals/otoclick.html}
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
%   REFERENCE: OK
  
if nargin>0
  error('This function does not take input arguments.')
end;

f=mfilename('fullpath');

s=load('-ascii',[f,'.asc']);
fs=44100;


