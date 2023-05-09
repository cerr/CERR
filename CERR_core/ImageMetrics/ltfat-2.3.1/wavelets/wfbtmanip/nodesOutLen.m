function Lc = nodesOutLen(nodeNo,L,outRange,doNoExt,wt)
%-*- texinfo -*-
%@deftypefn {Function} nodesOutLen
%@verbatim
%NODESOUTLEN Length of the node output
%   Usage:  Lc = nodesOutLen(nodeNo,inLen,doExt,wt);
%
%   Input parameters:
%         nodeNo     : Node index(es).
%         inLen      : Filter thee input signal length.
%         outRange   : Cell array. Each element is a vector of local out.
%         indexes.
%         doNoExt    : Expansive representation indicator.
%         wt         : Structure containing description of the filter tree.
%
%   Output parameters:
%         Lin        : Length of the node input signal 
%
%   NODESOUTLEN(nodeNo,inLen,doExt,treeStruct) return length of the input
%   signal of the node nodeNo. For definition of the structure see wfbinit.
%
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wfbtmanip/nodesOutLen.html}
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
if isempty(outRange)
    outRange = cellfun(@(nEl) 1:numel(nEl.g),wt.nodes(nodeNo),'UniformOutput',0);
end

Lc = zeros(sum(cellfun(@numel,outRange)),1);

inLens = nodesInLen(nodeNo,L,doNoExt,wt);

Lcidx = 1;
for ii=1:numel(inLens)
    nodeHlen = cellfun(@(nEl) numel(nEl.h),...
               wt.nodes{nodeNo(ii)}.g(outRange{ii}));
    nodea =  wt.nodes{nodeNo(ii)}.a(outRange{ii});
    
    if(~doNoExt)
       Lc(Lcidx:Lcidx+numel(nodeHlen)-1) = floor((inLens(ii)...
                                            +nodeHlen(:)-1)./nodea(:));
    else
       Lc(Lcidx:Lcidx+numel(nodeHlen)-1) = ceil(inLens(ii)./nodea(:)); 
    end
    Lcidx = Lcidx + numel(nodeHlen);
end






