function Lc = treeOutLen(L,doNoExt,wt)
%-*- texinfo -*-
%@deftypefn {Function} treeOutLen
%@verbatim
%TREEOUTLEN  Lengths of tree subbands
%   Usage:  Lc = treeOutLen(L,doNoExt,wt)
%
%   Input parameters:
%         L       : Input signal length.
%         doNoExt : Flag. Expansive = false, Nonexpansive=true  
%         wt      : Structure containing description of the filter tree.
%
%   Output parameters:
%         Lc : Subband lengths.
%
%   Lc = TREEOUTLEN(L,doNoExt,wt) returns lengths of tree subbands given
%   input signal length L and flag doNoExt. When true, the transform is
%   assumed to be non-expansive.
%   For definition of the structure see WFBINIT.
%
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wfbtmanip/treeOutLen.html}
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



[termN, rangeLoc, rangeOut] = treeBFranges(wt);
slice = ~cellfun(@isempty,rangeOut); % Limit to nodes with unconnected outputs
rangeOut=rangeOut(slice);
cRange = cell2mat(cellfun(@(rEl) rEl(:),rangeOut(:),...
                  'UniformOutput',0));

Lctmp = nodesOutLen(termN(slice),L,rangeLoc(slice),doNoExt,wt);
Lc = zeros(size(Lctmp));
Lc(cRange) = Lctmp;








