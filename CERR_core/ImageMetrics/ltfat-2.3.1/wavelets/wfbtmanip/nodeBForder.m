function nodesIdxs = nodeBForder(nodeNo,wt)
%-*- texinfo -*-
%@deftypefn {Function} nodeBForder
%@verbatim
%NODEBFORDER Nodes in the Breadth-First search order
%  Usage:  nodesIdxs = nodeBForder(nodeNo,wt)
%
%   Input parameters:
%         nodeNo : Id of a node.
%         wt     : Structure containing description of the filter tree.
%
%   Output parameters:
%         nodesIdxs   : Node indexes in the Breadth-First search order.
%
%   NODEBFORDER(nodeNo,wt) For definition of the structure see
%   wfbinit. nodeNo defaults to the root node if it is empty or equal
%   to 0.
%
%
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wfbtmanip/nodeBForder.html}
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


if isempty(nodeNo) || nodeNo==0 
   %find root
   nodeNo = find(wt.parents==0);
end

complainif_notposint(nodeNo,'NODEBFORDER');

nodesIdxs = [nodeNo,nodeSubtreeBF(nodeNo,wt)];


function nodesIdxs = nodeSubtreeBF(nodeNo,wt)
%NODESUBTREEBF Node subtree nodes in Breath-First order
%   Usage:  noOut = nodeSubtreeBF(nodeNo,wt);
%
%   Input parameters:
%         nodeNo  : Node index.
%         wt      : Structure containing description of the filter tree.
%
%   Output parameters:
%         noOut   : Nodes in a Breath-First order. 
%

% subtreeIdx = [];
% 
% children = treeStruct.children{nodeNo}(find(treeStruct.children{nodeNo}~=0));
% subtreeIdx(end+1:end+length(children)) = children;
% 
% for ii=1:length(children)
%    tmpSbIdx = nodeSubtreeBF(children(ii),treeStruct);
%    subtreeIdx(end+1:end+length(tmpSbIdx)) = tmpSbIdx;
% end

toGoTrough = [nodeNo];
nodesIdxs = [];
while ~isempty(toGoTrough)
  % chtmp = find(wt.children{toGoTrough(1)}~=0);
   chIdxtmp = wt.children{toGoTrough(1)}(wt.children{toGoTrough(1)}~=0);
   nodesIdxs = [nodesIdxs,chIdxtmp];
   toGoTrough = [toGoTrough(2:end),chIdxtmp];
end

