function [s,fs]=ltfatlogo()
%-*- texinfo -*-
%@deftypefn {Function} ltfatlogo
%@verbatim
%LTFATLOGO  Load the 'ltfatlogo' test signal
%   Usage:  s=ltfatlogo;
%
%   LTFATLOGO loads the 'ltfatlogo' signal. This is a sound synthezised
%   from an artificial spectrogram of the word 'LTFAT'. See the help of
%   LTFATTEXT.
%
%   [sig,fs]=LTFATLOGO additionally returns the sampling frequency fs.
%
%   The signal is 7200 samples long and recorded at 8 kHz. It has been
%   scaled to not produce any clipping.
%
%   Examples:
%   ---------
%
%   To produce a spectrogram of the logo, use:
%
%     sgram(ltfatlogo,8000,90);
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/signals/ltfatlogo.html}
%@seealso{ltfattext}
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

s = wavload([f,'.wav']);
fs=8000;

