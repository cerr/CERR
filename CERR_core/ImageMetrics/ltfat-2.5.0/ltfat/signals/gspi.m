function [s,fs]=gspi()
%GSPI  Load the 'glockenspiel' test signal
%
%   GSPI loads the 'glockenspiel' signal. This is a recording of a simple
%   tune played on a glockenspiel. It is 262144 samples long, mono, recorded
%   at 44100 Hz using 16 bit quantization.
%   
%   [sig,fs]=GSPI additionally returns the sampling frequency fs.
%
%   This signal, and other similar audio tests signals, can be found on
%   the EBU SQAM test signal CD http://tech.ebu.ch/publications/sqamcd.
%
%
%   Url: http://ltfat.github.io/doc/signals/gspi.html

% Copyright (C) 2005-2022 Peter L. Soendergaard <peter@sonderport.dk> and others.
% This file is part of LTFAT version 2.5.0
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
  
%   AUTHOR : Peter L. Søndergaard
%   TESTING: TEST_SIGNALS
%   REFERENCE: OK
  
if nargin>0
  error('This function does not take input arguments.')
end;

f=mfilename('fullpath');

% Load audio signal
s = wavload([f,'.wav']);
fs = 44100;


