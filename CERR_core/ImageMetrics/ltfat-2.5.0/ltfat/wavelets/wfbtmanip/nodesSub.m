function subNo = nodesSub(nodeNo,wt)


if(any(nodeNo>numel(wt.nodes)))
   error('%s: Invalid node index range. Number of nodes is %d.\n',upper(mfilename),numel(wt.nodes));
end

nodeNoa = cellfun(@(nEl) nEl.a,wt.nodes(nodeNo),'UniformOutput',0);
nodeNoUps = nodesFiltUps(nodeNo,wt);

nodesCount = numel(nodeNo);
subNo = cell(1,nodesCount);
for ii=1:nodesCount
   subNo{ii} = nodeNoUps(ii)*nodeNoa{ii};
end


%
%   Url: http://ltfat.github.io/doc/wavelets/wfbtmanip/nodesSub.html

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

