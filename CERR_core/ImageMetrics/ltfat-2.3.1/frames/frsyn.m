function outsig=frsyn(F,insig);
%-*- texinfo -*-
%@deftypefn {Function} frsyn
%@verbatim
%FRSYN  Frame synthesis operator
%   Usage: f=frsyn(F,c);
%
%   f=FRSYN(F,c) constructs a signal f from the frame coefficients c*
%   using the frame F. The frame object F must have been created using
%   FRAME.
%
%   Examples:
%   ---------
%
%   In the following example a signal f is constructed through the frame
%   synthesis operator using a Gabor frame. The coefficients associated with 
%   this Gabor expansion are contained in an identity matrix. The identity 
%   matrix corresponds to a diagonal in the time-frequency plane, that is, 
%   one atom at each time position with increasing frequency.:
%
%      a = 10;
%      M = 40;
%
%      F = frame('dgt', 'gauss', a, M);
%
%      c = framenative2coef(F, eye(40));
%
%      f = frsyn(F, c);
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/frames/frsyn.html}
%@seealso{frame, frana, plotframe}
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
  
complainif_notenoughargs(nargin,2,'FRSYN');
complainif_notvalidframeobj(F,'FRSYN');

L=framelengthcoef(F,size(insig,1));

F=frameaccel(F,L);

outsig=F.frsyn(insig);


