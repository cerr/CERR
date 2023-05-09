function L=comp_framelength_fusion(F,Ls);

%-*- texinfo -*-
%@deftypefn {Function} comp_framelength_fusion
%@verbatim
% This is highly tricky: Get the minimal transform length for each
% subframe, and set the length as the lcm of that.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_framelength_fusion.html}
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
Lsmallest=1;
for ii=1:F.Nframes
    Lsmallest=lcm(Lsmallest,framelength(F.frames{ii},1));
end;
L=ceil(Ls/Lsmallest)*Lsmallest;

% Verify that we did not screw up the assumptions.
for ii=1:F.Nframes
    if L~=framelength(F.frames{ii},L)
        error(['%s: Cannot determine a frame length. Frame no. %i does ' ...
               'not support a length of L=%i.'],upper(mfilename),ii,L);
    end;
end;


