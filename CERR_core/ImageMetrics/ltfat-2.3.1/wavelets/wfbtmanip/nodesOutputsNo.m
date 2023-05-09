function noOut = nodesOutputsNo(nodeNo,wt)
%-*- texinfo -*-
%@deftypefn {Function} nodesOutputsNo
%@verbatim
%NODESOUTPUTSNO Number of node Outputs
%   Usage:  noOut = nodesOutputsNo(nodeNo,wt);
%
%   Input parameters:
%         nodeNo  : Node index.
%         wt      : Structure containing description of the filter tree.
%
%   Output parameters:
%         noOut      : Number of node outputs. 
%
%   NODESOUTPUTSNO(nodeNo,wt) Return number of the terminal 
%   outputs of the node nodeNo. For definition of the structure
%   see wfbinit.
%
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wfbtmanip/nodesOutputsNo.html}
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

noOut = cellfun(@(nEl) numel(nEl.g), wt.nodes(nodeNo)) -...
        cellfun(@(chEl) numel(chEl(chEl~=0)), wt.children(nodeNo));





