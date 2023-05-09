function L=framelengthcoef(F,Ncoef);
%-*- texinfo -*-
%@deftypefn {Function} framelengthcoef
%@verbatim
%FRAMELENGTHCOEF  Frame length from coefficients
%   Usage: L=framelengthcoef(F,Ncoef);
%
%   FRAMELENGTHCOEF(F,Ncoef) returns the length of the frame F, such that
%   F is long enough to expand the coefficients of length Ncoef.
%
%   If instead a signal is given, call FRAMELENGTH.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/frames/framelengthcoef.html}
%@seealso{frame, framelength}
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
complainif_notposint(Ncoef,'Ncoef',callfun);
complainif_notvalidframeobj(F,callfun);


L = F.lengthcoef(Ncoef);
% sprintf for Octave compatibility
assert(abs(L-round(L))<1e-3,...
       sprintf('%s: There is a bug. L=%d should be an integer.',...
       upper(mfilename),L));
L=round(L);
    
% Verify the computed length
if ~(L==framelength(F,L))
    error(['%s: The coefficient number given does not correspond to a valid ' ...
           'set of coefficients for this type of frame.'],upper(mfilename));
    
end;

