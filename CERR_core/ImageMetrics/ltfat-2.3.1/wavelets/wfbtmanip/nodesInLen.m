function L = nodesInLen(nodeNo,inLen,doNoExt,wt)
%-*- texinfo -*-
%@deftypefn {Function} nodesInLen
%@verbatim
%NODESINLEN Length of the node input signal
%   Usage:  L = nodesInLen(nodeNo,inLen,doExt,treeStruct);
%
%   Input parameters:
%         nodeNo     : Node index.
%         inLen      : Filter thee input signal length.
%         doNoExt    : Expansive representation indicator.
%         wt         : Structure containing description of the filter tree.
%
%   Output parameters:
%         Lin        : Length of the node input signal 
%
%   NODESINLEN(nodeNo,inLen,doExt,treeStruct) return length of the input
%   signal of the node nodeNo. For definition of the structure see wfbinit.
%
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wfbtmanip/nodesInLen.html}
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

L = zeros(numel(nodeNo),1);
for nn=1:length(nodeNo)
    subPat = [];
    filtLenPat = [];
    tmpNodeNo = nodeNo(nn);

    while(wt.parents(tmpNodeNo))
       parentNo = wt.parents(tmpNodeNo);
       tmpIdx = find(wt.children{parentNo}==tmpNodeNo);
       subPat(end+1) = wt.nodes{parentNo}.a(tmpIdx);
       filtLenPat(end+1) = length(wt.nodes{parentNo}.g{tmpIdx}.h);
       tmpNodeNo=parentNo;
    end

    subPat = subPat(end:-1:1);
    filtLenPat = filtLenPat(end:-1:1);

    L(nn) = inLen;
    if(~doNoExt)
        for ii=1:length(subPat)
            L(nn) = floor((L(nn)+filtLenPat(ii)-1)/subPat(ii));
        end
    else
        for ii=1:length(subPat)
            L(nn) = ceil(L(nn)/subPat(ii)); 
        end
    end
end


