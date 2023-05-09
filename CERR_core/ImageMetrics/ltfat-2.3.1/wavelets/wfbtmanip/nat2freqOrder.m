function wt = nat2freqOrder(wt,varargin)
%-*- texinfo -*-
%@deftypefn {Function} nat2freqOrder
%@verbatim
%NAT2FREQORDER Natural To Frequency Ordering
%   Usage:  wt = nat2freqOrder(wt);
%
%   Input parameters:
%         wt    : Structure containing description of the filter tree.
%
%   Output parameters:
%         wt    : Structure containing description of the filter tree.
%
%   NAT2FREQORDER(wt) Creates new wavelet filterbank tree definition
%   with permuted order of some filters for purposes of the correct frequency
%   ordering of the resultant identical filters and coefficient subbands. 
%   For definition of the structure see WFBINIT and DTWFBINIT.
%
%   NAT2FREQORDER(wt,nodes) does the same but works only with nodes
%   listed in nodes.
%
%   NAT2FREQORDER(...,'rev') changes the frequency ordering back to
%   natural ordering.
%
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wfbtmanip/nat2freqOrder.html}
%@seealso{wfbtinit, wfbtmultid, nodebforder}
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

complainif_notenoughargs(nargin,1,'NAT2FREQORDER');

do_rev = ~isempty(varargin(strcmp('rev',varargin)));

if do_rev
    %Remove the 'rev' flag from varargin
    varargin(strcmp('rev',varargin)) = [];
end

bftreepath = nodeBForder(0,wt);

if isempty(varargin)
   treePath = bftreepath(2:end);% skip root
else
   % Work with specified nodes only
   nodes = varargin{1}; 
   % Omit root
   nodes(wt.parents(nodes)==0) = [];
   % Use the rest 
   treePath = nodes;
end

% Dual-tree complex wavelet packets require some more tweaking.
 if isfield(wt,'dualnodes')
     
    locIdxs = arrayfun(@(tEl) find(wt.children{wt.parents(tEl)}==tEl,1),treePath);
    treeNodes = treePath(rem(locIdxs,2)~=1);
    % Root was removed so the following will not fail
    jj = treeNodes(find(treeNodes(wt.parents(wt.parents(treeNodes))==0),1));
 
    while ~isempty(jj) && ~isempty(wt.children{jj})
        sanChild = postpad(wt.children{jj},numel(wt.nodes{jj}.g));
        % Reverse child nodes
        wt.children{jj} = sanChild(end:-1:1); 
 
        if do_rev
          jj = wt.children{jj}(1);
        else 
          jj = wt.children{jj}(end);
        end
        
    end
 
 end

% Array indexed by nodeId
reordered = zeros(size(bftreepath));

% Long version
if 1
    for nodeId=bftreepath
        ch = postpad(wt.children{nodeId},numel(wt.nodes{nodeId}.g));
        odd = 1;
        if reordered(nodeId) && rem(numel(ch),2)==1
            odd = 0;
        end 

        for m=0:numel(ch)-1
            if ch(m+1) ~= 0
                if rem(m,2)==odd
                   reordered(ch(m+1)) = 1;
                end
            end
        end    
    end
end

% Reorder filters
for nodeId=treePath(logical(reordered(treePath)))
    wt = reorderFilters(nodeId,wt);
end

function wt = reorderFilters(nodeId,wt)
% now for the filter reordering
wt.nodes{nodeId}.g = wt.nodes{nodeId}.g(end:-1:1);
wt.nodes{nodeId}.h = wt.nodes{nodeId}.h(end:-1:1);
wt.nodes{nodeId}.a = wt.nodes{nodeId}.a(end:-1:1);

% Do the same with the dual tree if it exists
if isfield(wt,'dualnodes')
    wt.dualnodes{nodeId}.g = wt.dualnodes{nodeId}.g(end:-1:1);
    wt.dualnodes{nodeId}.h = wt.dualnodes{nodeId}.h(end:-1:1);
    wt.dualnodes{nodeId}.a = wt.dualnodes{nodeId}.a(end:-1:1);
end















