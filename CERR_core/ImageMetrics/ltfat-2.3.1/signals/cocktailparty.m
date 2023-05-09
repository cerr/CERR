function [s,fs]=cocktailparty()
%-*- texinfo -*-
%@deftypefn {Function} cocktailparty
%@verbatim
%COCKTAILPARTY  Load the 'cocktailparty' test signal
%   Usage:  s=cocktailparty;
%
%   COCKTAILPARTY loads the 'cocktailparty' signal. It is a recording of a
%   male native English speaker pronouncing the sentence "The cocktail party
%   effect refers to the ability to focus on a single talker among a mixture
%   of conversations in background noises".
%
%   [sig,fs]=COCKTAILPARTY additionally returns the sampling frequency fs.
%
%   The signal is 363200 samples long and recorded at 44.1 kHz in an
%   anechoic environment.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/signals/cocktailparty.html}
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

%   AUTHOR : James harte and Peter L. Soendergaard
%   TESTING: TEST_SIGNALS
%   REFERENCE: OK

if nargin>0
  error('This function does not take input arguments.')
end;

f=mfilename('fullpath');

s=wavload([f,'.wav']);
fs=44100;

