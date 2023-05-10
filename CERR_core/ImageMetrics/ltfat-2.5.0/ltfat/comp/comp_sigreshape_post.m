function f=comp_sigreshape_post(f,fl,wasrow,remembershape)
%COMP_SIGRESHAPE_POST
%
%
%   Url: http://ltfat.github.io/doc/comp/comp_sigreshape_post.html

% Copyright (C) 2005-2022 Peter L. Soendergaard <peter@sonderport.dk> and others.
% This file is part of LTFAT version 2.5.0
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

%   AUTHOR : Peter L. Søndergaard.
%   TESTING: OK
%   REFERENCE: OK

% Get original dimensionality
fd=length(remembershape);

if fd>2
  f=reshape(f,[fl,remembershape(2:fd)]);
else
  if wasrow
    f=f.';
  end;
end;



