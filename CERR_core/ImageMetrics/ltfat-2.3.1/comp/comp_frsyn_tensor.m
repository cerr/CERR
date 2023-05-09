function outsig=comp_frsyn_tensor(F,insig)

outsig=frsyn(F.frames{1},insig);
perm=circshift((1:F.Nframes).',-1);
for ii=2:F.Nframes
    outsig=permute(outsig,perm);
    outsig=frsyn(F.frames{ii},outsig);
end;
outsig=permute(outsig,perm);

%-*- texinfo -*-
%@deftypefn {Function} comp_frsyn_tensor
%@verbatim
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_frsyn_tensor.html}
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

