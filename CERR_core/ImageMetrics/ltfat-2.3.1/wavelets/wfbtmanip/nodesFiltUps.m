function upsNo = nodesFiltUps(nodeNo,wt)
%-*- texinfo -*-
%@deftypefn {Function} nodesFiltUps
%@verbatim
%NODEFILTUPS  Node upsamplig factor
%   Usage:  upsNo = nodesFiltUps(nodeNo,wt)
%
%   Input parameters:
%         wt  : Structure containing description of the filter tree.
%
%   Output parameters:
%         upsNo : Accumulated upsampling factor along path to root.
%
%   NODESFILTUPS(wt) Returns upsampling factor, which can be used to
%   upsample the node filters using the a-trous algorithm.
%   For definition of the structure see WFBINIT.
%
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wfbtmanip/nodesFiltUps.html}
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

nodesCount = numel(nodeNo);
upsNo = zeros(nodesCount,1);
for ii=1:nodesCount
   tmpNodeNo = nodeNo(ii);
   upsNo(ii) = 1;
   while(wt.parents(tmpNodeNo))
       parentNo = wt.parents(tmpNodeNo);
       upsNo(ii)=upsNo(ii)*wt.nodes{parentNo}.a(wt.children{parentNo}==tmpNodeNo);
       tmpNodeNo=parentNo;
   end
end

