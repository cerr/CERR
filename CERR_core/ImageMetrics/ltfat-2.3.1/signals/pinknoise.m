function outsig = pinknoise(varargin)
%-*- texinfo -*-
%@deftypefn {Function} pinknoise
%@verbatim
% PINKNOISE Generates a pink noise signal
%   Usage: outsig = pinknoise(siglen,nsigs);
%
%   Input parameters:
%       siglen    : Length of the noise (samples)
%       nsigs     : Number of signals (default is 1)
%
%   Output parameters:
%       outsig    : siglen xnsigs signal vector
%
%   PINKNOISE(siglen,nsigs) generates nsigs channels containing pink noise
%   (1/f spectrum) with the length of siglen. The signals are arranged as
%   columns in the output.
%
%   PINKNOISE is just a wrapper around noise(...,'pink');
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/signals/pinknoise.html}
%@seealso{noise}
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

outsig = noise(varargin{:},'pink');


