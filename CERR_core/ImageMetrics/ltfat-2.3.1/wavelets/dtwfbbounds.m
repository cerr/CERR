function [AF,BF]=dtwfbbounds(dualwt,L)
%-*- texinfo -*-
%@deftypefn {Function} dtwfbbounds
%@verbatim
%DTWFBBOUNDS Frame bounds of DTWFB
%   Usage: fcond=dtwfbbounds(dualwt,L);
%          [A,B]=dtwfbbounds(dualwt,L);
%          [...]=dtwfbbounds(dualwt);
%
%   DTWFBBOUNDS(dualwt,L) calculates the ratio B/A of the frame bounds
%   of the dual-tree filterbank specified by dualwt for a system of 
%   length L. The ratio is a measure of the stability of the system.
%
%   DTWFBBOUNDS(dualwt) does the same thing, but L is the next compatible 
%   length bigger than the longest filter in the identical filterbank.
%
%   [A,B]=DTWFBBOUNDS(...) returns the lower and upper frame bounds
%   explicitly.
%
%   See DTWFB for explanation of parameter dualwt.
%
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/dtwfbbounds.html}
%@seealso{dtwfb, filterbankbounds}
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

% AUTHOR: Zdenek Prusa

complainif_notenoughargs(nargin,1,'DTWFBBOUNDS');

dualwt = dtwfbinit({'strict',dualwt},'nat');

if nargin<2 
    L = [];
end;

if ~isempty(L)
   if L~=wfbtlength(L,dualwt)
          error(['%s: Specified length L is incompatible with the length of ' ...
                 'the time shifts.'],upper(mfilename));
   end
end

% Do the equivalent filterbank using multirate identity property
[gmultid,amultid] = dtwfb2filterbank(dualwt,'complex');

if isempty(L)
   L = wfbtlength(max(cellfun(@(gEl) numel(gEl.h),gmultid)),dualwt);  
end


% Do the equivalent uniform filterbank
[gu,au] = nonu2ufilterbank(gmultid,amultid);

if nargout<2
   AF = filterbankbounds(gu,au,L);
elseif nargout == 2
   [AF, BF] = filterbankbounds(gu,au,L);
end


