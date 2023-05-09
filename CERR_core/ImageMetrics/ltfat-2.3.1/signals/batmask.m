function c=batmask()
%-*- texinfo -*-
%@deftypefn {Function} batmask
%@verbatim
%BATMASK  Load a Gabor multiplier symbol for the 'bat' test signal
%   Usage:  c=batmask;
%
%   BATMASK loads a Gabor multiplier with a 0/1 symbol that masks out
%   the main contents of the 'bat' signal. The symbol fits a Gabor
%   multiplier with lattice given by a=10 and M=40.
%
%   The mask was created manually using a image processing program. The
%   mask is symmetric, such that the result will be real valued if the
%   multiplier is applied to a real valued signal using a real valued
%   window.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/signals/batmask.html}
%@seealso{bat}
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
%   TESTING: TEST_BATMASK
%   REFERENCE: OK
  
if nargin>0
  error('This function does not take input arguments.')
end;

f=mfilename('fullpath');

c=load('-ascii',[f,'.asc']);


