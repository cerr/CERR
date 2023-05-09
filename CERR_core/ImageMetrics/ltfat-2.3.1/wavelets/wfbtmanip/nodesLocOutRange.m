function outRange = nodesLocOutRange(nodeNo,wt)
%-*- texinfo -*-
%@deftypefn {Function} nodesLocOutRange
%@verbatim
%NODESLOCOUTRANGE Node output index range of the terminal outputs
%   Usage:  outRange = nodesLocOutRange(nodeNo,wt);
%
%   Input parameters:
%         nodeNo     : Node index.
%         wt : Structure containing description of the filter tree.
%
%   Output parameters:
%         noOut      : Index range. 
%
%   NODESLOCOUTRANGE(nodeNo,wt) returns range of indexes of the
%   terminal outputs of the node nodeNo. For definition of the structure
%   see wfbinit.
%
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wfbtmanip/nodesLocOutRange.html}
%@seealso{wfbtinit}
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

if(any(nodeNo>numel(wt.nodes)))
   error('%s: Invalid node index range. Number of nodes is %d.\n',upper(mfilename),numel(wt.nodes));
end


nodesCount = length(nodeNo);
outRange = cell(nodesCount,1); 


nodeChans = cellfun(@(nEl) numel(nEl.g), wt.nodes(nodeNo));
chIdx = cellfun(@(chEl) find(chEl~=0), wt.children(nodeNo),'UniformOutput',0);


for ii = 1:nodesCount
 outRangeTmp = 1:nodeChans(ii);
 outRangeTmp(chIdx{ii}) = [];
 outRange{ii} = outRangeTmp;
end




