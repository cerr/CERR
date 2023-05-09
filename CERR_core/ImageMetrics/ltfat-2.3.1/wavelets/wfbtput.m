function wt = wfbtput(d,k,w,wt,forceStr)
%-*- texinfo -*-
%@deftypefn {Function} wfbtput
%@verbatim
%WFBTPUT  Put node to the filterbank tree
%   Usage:  wt = wfbtput(d,k,w,wt);
%           wt = wfbtput(d,k,w,wt,'force');
%
%   Input parameters:
%           d   : Level in the tree (0 - root).
%           k   : Index (array of indexes) of the node at level d (starting at 0).
%           w   : Node, basic wavelet filterbank.
%           wt  : Wavelet filterbank tree structure (as returned from
%                 WFBTINIT).
%
%   Output parameters:
%           wt : Modified filterbank structure.
%
%   WFBTPUT(d,k,w,wt) puts the basic filterbank w to the filter
%   tree structure wt at level d and index(es) k. The output is a
%   modified tree structure. d and k have to specify unconnected output
%   of the leaf node. Error is issued if d and k points to already
%   existing node. For possible formats of parameter w see help of FWT.
%   Parameter wt has to be a structure returned by WFBTINIT.
%   
%   WFBTPUT(d,k,w,wt,'force') does the same but replaces node at d and k*
%   if it already exists. If the node to be replaced has any children, 
%   the number of outputs of the replacing node have to be equal to number of
%   outputs of the node beeing replaced.
%
%   Examples:
%   ---------
%
%   This example shows magnitude frequency responses of a tree build from
%   the root:
%
%      % Initialize empty struct
%      wt = wfbtinit();
%      % Put root node to the empty struct
%      wt1 = wfbtput(0,0,'db8',wt);
%      % Connect a different nodes to both outputs of the root
%      wt2 = wfbtput(1,[0,1],'db10',wt1);
%      % Connect another nodes just to high-pass outputs of nodes just added
%      wt3 = wfbtput(2,[1,3],'db10',wt2);
%      % Add another node at level 3
%      wt4 = wfbtput(3,1,'db16',wt3);
%      
%      % Create identical filterbanks
%      [g1,a1] = wfbt2filterbank(wt1,'freq');
%      [g2,a2] = wfbt2filterbank(wt2,'freq');
%      [g3,a3] = wfbt2filterbank(wt3,'freq');
%      [g4,a4] = wfbt2filterbank(wt4,'freq');
%
%      % Plot frequency responses of the growing tree. Linear scale 
%      % (both axis) is used and positive frequencies only are shown.
%      subplot(4,1,1);
%      filterbankfreqz(g1,a1,1024,'plot','linabs','posfreq');
%      subplot(4,1,2);
%      filterbankfreqz(g2,a2,1024,'plot','linabs','posfreq');
%      subplot(4,1,3);
%      filterbankfreqz(g3,a3,1024,'plot','linabs','posfreq');
%      subplot(4,1,4);
%      filterbankfreqz(g4,a4,1024,'plot','linabs','posfreq');
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wfbtput.html}
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

% AUTHOR: Zdenek Prusa
  
if nargin<4
   error('%s: Too few input parameters.',upper(mfilename)); 
end

%if isfield(wt,'dualnodes')
%    error('%s: Cannot modify the dual-tree struct.',upper(mfilename));
%end

do_force = 0;
if nargin==5
    if ~ischar(forceStr)
        error('%s: Fifth parameter should be a string.',upper(mfilename));
    end
    if strcmpi(forceStr,'force')
        do_force = 1;
    end
end

% This was replaced. Calling ltfatargheler was too slow.
%definput.flags.force = {'noforce','force'};
%[flags,kv]=ltfatarghelper({},definput,varargin);

node = fwtinit(w);

oldnodecount = numel(wt.nodes);
nodeschanged = [];

[nodeNoArray,nodeChildIdxArray] = depthIndex2NodeNo(d,k,wt);

for ii=1:numel(nodeNoArray)
 nodeNo = nodeNoArray(ii);
 nodeChildIdx = nodeChildIdxArray(ii);
if(nodeNo==0)
    % adding root 
    if(~isempty(find(wt.parents==0,1)))
        if(do_force)
           rootId = find(wt.parents==0,1);
           % if root has children, check if the new root has the same
           % number of them
           if(~isempty(find(wt.children{rootId}~=0,1)))
              if(length(w.g)~=length(wt.nodes{rootId}.g))
                 error('%s: The replacing root have to have %d filters.',mfilename,length(wt.nodes{rootId}.g)); 
              end
           end
        else
            error('%s: Root already defined. Use FORCE option to replace.',mfilename);  
        end
        wt.nodes{rootId} = node;
        nodeschanged(end+1) = rootId;
        
        if isfield(wt,'dualnodes') 
            wt.dualnodes{rootId} = node; 
        end
        continue;
    end
    wt.nodes{end+1} = node;
    wt.parents(end+1) = nodeNo;
    wt.children{end+1} = [];
    
    if isfield(wt,'dualnodes') 
        wt.dualnodes{end+1} = node; 
    end
    continue;
end

childrenIdx = find(wt.children{nodeNo}~=0);
found = find(childrenIdx==nodeChildIdx,1);
if(~isempty(found))
   if(do_force)
     %check if childrenIdx has any children
     tmpnode = wt.children{nodeNo}(found);  
     if(~isempty(find(wt.children{tmpnode}~=0, 1)))
         if length(node.g)~=length(wt.nodes{tmpnode}.g)
            error('%s: The replacing node must have %d filters.',mfilename,length(wt.nodes{tmpnode}.g)); 
         end
     end
     wt.nodes{tmpnode} = node;
     nodeschanged(end+1) = tmpnode;
     if isfield(wt,'dualnodes') 
         wt.dualnodes{tmpnode} = node; 
     end
     % Since we are replacing a node, all links are already correct
     continue;
   else
       error('%s: Such node (depth=%d, idx=%d) already exists. Use FORCE option to replace.',mfilename,d,k); 
   end
end

wt.nodes{end+1} = node;
wt.parents(end+1) = nodeNo;
wt.children{end+1} = [];
wt.children{nodeNo}(nodeChildIdx) = numel(wt.parents);

if isfield(wt,'dualnodes') 
    wt.dualnodes{end+1} = node; 
end

end

% We have to correctly shuffle filters in the just added (or modified) filters
% if the tree was already defined as frequency ordered.
if wt.freqOrder
      wt = nat2freqOrder(wt,[nodeschanged,oldnodecount+1:numel(wt.nodes)]);
end


