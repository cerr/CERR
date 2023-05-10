function a = treeSub(wt)
%TREESUB  Identical subsampling factors
%   Usage:  a = treeSub(wt)
%
%   Input parameters:
%         wt  : Structure containing description of the filter tree.
%
%   Output parameters:
%         a : Subsampling factors.
%
%   a = TREESUB(wt) returns subsampling factors asociated with the tree
%   subbands. For definition of the structure see WFBINIT.
%
%   See also: wfbtinit
%
%
%   Url: http://ltfat.github.io/doc/wavelets/wfbtmanip/treeSub.html

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

% Get nodes in BF order
nodesBF = nodeBForder(0,wt);
% All nodes with at least one final output.
termNslice = nodesOutputsNo(nodesBF,wt)~=0;
termN = nodesBF(termNslice);

% Range in filter outputs
outRangeTermN = nodesLocOutRange(termN,wt);

%cRangeTermN = nodesOutRange(termN,wt);
rangeOut = treeOutRange(wt);
% Get only nodes with some output
cRangeTermN = rangeOut(termNslice);

noOut = sum(cellfun(@numel,cRangeTermN));
% Subsampling factors of the terminal nodes
subTermN = nodesSub(termN,wt);

a = zeros(noOut, 1);
for ii=1:numel(termN)
   a(cRangeTermN{ii}) = subTermN{ii}(outRangeTermN{ii});
end


