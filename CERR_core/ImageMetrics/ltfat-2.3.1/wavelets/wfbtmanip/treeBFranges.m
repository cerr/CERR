function [nodesBF, rangeLoc, rangeOut] = treeBFranges(wt,varargin)
%-*- texinfo -*-
%@deftypefn {Function} treeBFranges
%@verbatim
%TREEBFRANGES Tree nodes output ranges in BF order
%   Usage: [nodesBF, rangeLoc, rangeOut] = treeBFranges(wt);
%          [nodesBF, rangeLoc, rangeOut] = treeBFranges(wt,'rev');
%
%   Input parameters:
%         wt       : Filterbank tree struct.
%   Output parameters:
%         nodesBF  : All nodes in a breadth-first order
%         rangeLoc : Local ranges of unconnected (terminal) outputs
%         rangeOut : Global ranges of unconnected (terminal) outputs
%
%   [nodesBF, rangeLoc, rangeOut] = TREEBFRANGES(wt) is a helper function
%   extracting all nodes of a tree in a BF order (root and low-pass first) 
%   (numeric array of indexes nodesBF), and two cell arrays of ranges of
%   outputs. Each element of rangeLoc specifies range of unconnected
%   outputs of a node with at the corresponding position in nodesBF.
%   Elements rangeOut specify contain the resulting global indexes 
%   (in the resulting coefficient cell array) of such unconnected nodes.
%
%   [nodesBF, rangeLoc, rangeOut] = TREEBFRANGES(wt,'rev') does the same 
%   but the arrays are reversed.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wfbtmanip/treeBFranges.html}
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


nodesBF = nodeBForder(0,wt);
do_rev = 0;
if ~isempty(varargin(strcmp('rev',varargin)));
   nodesBF = fliplr(nodesBF); 
   do_rev = 1;
end

rangeLoc = nodesLocOutRange(nodesBF,wt);

rangeOut = treeOutRange(wt);
if do_rev
    %rangeOut = nodesOutRange(nodesBF,wt);
    rangeOut = rangeOut(end:-1:1);
end


