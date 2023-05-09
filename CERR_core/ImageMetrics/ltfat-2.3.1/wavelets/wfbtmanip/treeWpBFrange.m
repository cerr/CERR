function [pOutIdxs,chOutIdxs] = treeWpBFrange(wt)
%-*- texinfo -*-
%@deftypefn {Function} treeWpBFrange
%@verbatim
%TREEWPBFRANGE Wavelet packet tree output ranges in BF order
%   Usage: [pOutIdxs,chOutIdxs] = treeBFranges(wt);
%
%   Input parameters:
%         wt       : Filterbank tree struct.
%   Output parameters:
%         pOutIdxs  : Array of parent nodes in BF order
%         chOutIdxs : Cell array of children nodes in BF order
%
%   [pOutIdxs,chOutIdxs] = treeBFranges(wt) is a helper function
%   determining direct relationship between nodes in tree wt. 
%   Elements in both returned arrays are ordered according to the BF order.
%   pOutIdxs is array of indices in the subbands
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wfbtmanip/treeWpBFrange.html}
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

treePath = nodeBForder(0,wt);
trLen = numel(treePath);
pOutIdxs = zeros(1,trLen);
chOutIdxs = cell(1,trLen);
pRunIdx = [0];
chRunIdx = 1;
% do trough tree and look for nodeNo and its parent
for ii=1:trLen
    tmpfiltNo = length(wt.nodes{treePath(ii)}.g);
    locRange = nodesLocOutRange(treePath(ii),wt);
    diffRange = 1:tmpfiltNo;
    diffRange(locRange{1})=[];
    chOutIdxs{ii} = chRunIdx:chRunIdx+tmpfiltNo-1;
    chRunIdx = chRunIdx + tmpfiltNo;
    pOutIdxs(ii) = pRunIdx(1);
    pRunIdx = [pRunIdx(2:end),chOutIdxs{ii}(diffRange)];
end

pOutIdxs = pOutIdxs(end:-1:1); 
chOutIdxs = chOutIdxs(end:-1:1);



