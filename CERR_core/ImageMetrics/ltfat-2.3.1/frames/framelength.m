function L=framelength(F,Ls);
%-*- texinfo -*-
%@deftypefn {Function} framelength
%@verbatim
%FRAMELENGTH  Frame length from signal
%   Usage: L=framelength(F,Ls);
%
%   FRAMELENGTH(F,Ls) returns the length of the frame F, such that
%   F is long enough to expand a signal of length Ls.
%
%   If the frame length is longer than the signal length, the signal will be
%   zero-padded by FRANA.
%
%   If instead a set of coefficients are given, call FRAMELENGTHCOEF.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/frames/framelength.html}
%@seealso{frame, framelengthcoef, frameclength}
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
  
callfun = upper(mfilename);
complainif_notenoughargs(nargin,2,callfun);
complainif_notposint(Ls,'Ls',callfun);
complainif_notvalidframeobj(F,callfun);

% .length field is mandatory
L=F.length(Ls);

