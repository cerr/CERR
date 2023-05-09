function [nodeNo,nodeChildIdx] = depthIndex2NodeNo(d,k,wt)
%-*- texinfo -*-
%@deftypefn {Function} depthIndex2NodeNo
%@verbatim
%DEPTHINDEX2NODENO Get node from depth and index in the tree
%   Usage: [nodeNo,nodeChildIdx] = depthIndex2NodeNo(d,k,wt)
%
%   [nodeNo,nodeChildIdx] = DEPTHINDEX2NODENO(d,k,wt) returns node 
%   nodeNo and an array of its children nodes nodeChildIdx positioned
%   in depth g and index k in the tree wt.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wfbtmanip/depthIndex2NodeNo.html}
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
if(d==0)
    nodeNo=0;
    nodeChildIdx=0;
    return;
end

% find ordered nodes at depth d-1
nodesNo = getNodesInDepth(d,wt);
if(isempty(nodesNo))
   error('%s: Depth of the tree is less than given d.',mfilename); 
end

% k is index in children of ordered nodes at depth d

nodeNo = zeros(numel(k),1);
nodeChildIdx = zeros(numel(k),1);
chNo = cumsum(cellfun( @(nEl) length(nEl.g),wt.nodes(nodesNo)));
chNoZ = [0;chNo(:)];

for kIdx=1:numel(k)
    ktmp = k(kIdx);
    idx = find(chNo>ktmp,1);
    if isempty(idx)
       error('%s: Index k=%i out of bounds.',mfilename,ktmp); 
    end    
    nodeNo(kIdx) = nodesNo(idx);
    nodeChildIdx(kIdx) = ktmp-chNoZ(idx)+1;
end

function nodd = getNodesInDepth(d,wt)
% find all nodes with d steps to the root ordered
if d==1
    % return root
    nodd = find(wt.parents==0);
    return;
end    

nbf = nodeBForder(0,wt);
nbfTmp = nbf;
tempd = 0;
while tempd<d
    nbf(nbfTmp==0) = [];
    nbfTmp(nbfTmp==0) = [];
    nbfTmp = wt.parents(nbfTmp);
    tempd = tempd+1;
end
nodd = nbf(nbfTmp==0);



