function red=framered(F);
%-*- texinfo -*-
%@deftypefn {Function} framered
%@verbatim
%FRAMERED  Redundancy of a frame
%   Usage  red=framered(F);
%
%   FRAMERED(F) computes the redundancy of a given frame F. If the
%   redundancy is larger than 1 (one), the frame transform will produce more
%   coefficients than it consumes. If the redundancy is exactly 1 (one),
%   the frame is a basis.
%
%   Examples:
%   ---------
%
%   The following simple example shows how to obtain the redundancy of a
%   Gabor frame:
%
%     F=frame('dgt','gauss',30,40);
%     framered(F)
%
%   The redundancy of a basis is always one:
%
%     F=frame('wmdct','gauss',40);
%     framered(F)
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/frames/framered.html}
%@seealso{frame, frana, framebounds}
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

complainif_notenoughargs(nargin,1,'FRAMERED');
complainif_notvalidframeobj(F,'FRAMERED');

% .red field is mandatory so no checking here
red=F.red;
  

