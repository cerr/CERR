function c = comp_dtwfb(f,nodes,dualnodes,rangeLoc,rangeOut,ext,do_complex)

% First tree
%
%   Url: http://ltfat.github.io/doc/comp/comp_dtwfb.html

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
c1 = comp_wfbt(f,nodes,rangeLoc,rangeOut,ext);
% Second tree
c2 = comp_wfbt(f,dualnodes,rangeLoc,rangeOut,ext);

% Combine outputs of trees
c = cellfun(@(crEl,ciEl) (crEl+1i*ciEl)/2,c1,c2,'UniformOutput',0);

if do_complex
   % Non-real specific
   cneg = cellfun(@(crEl,ciEl) (crEl-1i*ciEl)/2,c1,c2,...
                  'UniformOutput',0);

   c = [c;cneg(end:-1:1)];
end

