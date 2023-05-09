function [s,fs]=linus()
%-*- texinfo -*-
%@deftypefn {Function} linus
%@verbatim
%LINUS  Load the 'linus' test signal
%   Usage:  s=linus;
%
%   LINUS loads the 'linus' signal. It is a recording of Linus Thorvalds
%   pronouncing the words "Hello. My name is Linus Thorvalds, and I
%   pronounce Linux as Linux".
%
%   The signal is 41461 samples long and is sampled at 8 kHz.
%
%   [sig,fs]=LINUS additionally returns the sampling frequency fs.
%
%   See http://www.paul.sladen.org/pronunciation/.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/signals/linus.html}
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

s=wavload([f,'.wav']);
fs=8000;

