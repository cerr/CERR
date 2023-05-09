function wt = nodeSubtreeDelete(nodeNo,wt)
%-*- texinfo -*-
%@deftypefn {Function} nodeSubtreeDelete
%@verbatim
%DELETESUBTREE Removes subtree with root node
%   Usage:  wt = nodeSubtreeDelete(nodeNo,wt)
%
%   Input parameters:
%         nodeNo   : Node index.
%         wt       : Structure containing description of the filter tree.
%
%   Output parameters:
%         wt       : Modified wt.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wfbtmanip/nodeSubtreeDelete.html}
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

complainif_notenoughargs(nargin,2,'DELETESUBTREE');
complainif_notposint(nodeNo,'DELETESUBTREE');

% All nodes to be deleted in breadth-first order
toDelete = nodeBForder(nodeNo,wt);

% Start deleting from the deepest nodes to avoid deleting nodes with
% children
for ii = length(toDelete):-1:1
  wt = nodeDelete(toDelete(ii),wt); 
  biggerIdx = toDelete>toDelete(ii);
  toDelete(biggerIdx) = toDelete(biggerIdx) - 1;
end

%wt = nodeDelete(nodeNo,wt); 

function wt = nodeDelete(nodeNo,wt)
%DELETENODE Removes specified node from the tree
%   Usage:  wt = nodeDelete(nodeNo,wt)
%
%   Input parameters:
%         nodeNo   : Node index.
%         wt       : Structure containing description of the filter tree.
%
%   Output parameters:
%         wt       : Modified wt.

complainif_notenoughargs(nargin,2,'DELETENODE');
complainif_notposint(nodeNo,'DELETENODE');

if any(wt.children{nodeNo}~=0)
    error('%s: Deleting a non-leaf node!',upper(mfilename));
end

% Removing a root node
if wt.parents(nodeNo)==0
    % Better clear all fields, than simply call wfbtinit
    fNames = fieldnames(wt);
    for ii=1:numel(fNames)
        wt.(fNames{ii})(:) = [];
    end
    return;
end

% Remove the node from it's parent children node list
parId = wt.parents(nodeNo);
wt.children{parId}(wt.children{parId}==nodeNo) = 0;

% newIdx = 1:length(wt.nodes);
% newIdx = newIdx(find(newIdx~=nodeNo));
% wt.nodes = wt.nodes(newIdx);
% wt.parents = wt.parents(newIdx); 
% wt.children = wt.children(newIdx);

% Remove the node from the structure completely
wt.nodes(nodeNo) = [];

if isfield(wt,'dualnodes')
    wt.dualnodes(nodeNo) = [];
end

wt.parents(nodeNo) = []; 
wt.children(nodeNo) = [];

% Since node was removed, the interconnections are now wrong. 
% Let's fix that.
for ii =1:length(wt.children)
    biggerIdx = wt.children{ii}>nodeNo;
    wt.children{ii}(biggerIdx) = wt.children{ii}(biggerIdx)-1;
end

% .. ant the same in the parents array
biggerIdx = wt.parents>nodeNo;
wt.parents(biggerIdx) = wt.parents(biggerIdx)-1;

