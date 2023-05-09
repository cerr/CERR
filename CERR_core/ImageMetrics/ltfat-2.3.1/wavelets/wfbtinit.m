  function [wt,info] = wfbtinit(wtdef,varargin)
%-*- texinfo -*-
%@deftypefn {Function} wfbtinit
%@verbatim
%WFBTINIT Initialize Filterbank Tree
%   Usage:  wt = wfbtinit(wtdef);
%
%   Input parameters:
%         wtdef : Filterbank tree definition.
%
%   Output parameters:
%         wt    : Structure describing the filter tree.
%
%   WFBTINIT({w,J,flag}) creates a filterbank tree of depth J. The
%   parameter w defines a basic wavelet filterbank. For all possible 
%   formats see FWT.  The following optional flags (still inside of the
%   cell-array) are recognized:
%
%   'dwt','full','doubleband','quadband','octaband'
%     Type of the tree to be created.
%
%   WFBTINIT({w,J,flag,'mod',mod}) creates a filterbank tree as before,
%   but modified according to the value of mod.
%   Recognized options:
%
%   'powshiftable'
%      Changes subsampling factors of the root to 1. This results in redundant
%      near-shift invariant representation.
%
%   The returned structure wt has the following fields:
%
%   .nodes     
%      Cell-array of structures obtained from FWTINIT. Each element
%      define a basic wavelet filterbank.
%
%   .children  
%      Indexes of children nodes
%
%   .parents   
%      Indexes of a parent node
%
%   .forder 
%      Frequency ordering of the resultant frequency bands.
%
%   The structure together with functions from the wfbtmanip 
%   subdirectory acts as an abstract data structure tree. 
%
%   Regular WFBTINIT flags:
%
%   'freq','nat'
%     Frequency or natural ordering of the coefficient subbands. The direct
%     usage of the wavelet tree ('nat' option) does not produce coefficient
%     subbans ordered according to the frequency. To achieve that, some
%     filter shuffling has to be done ('freq' option).
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wfbtinit.html}
%@seealso{wfbtput, wfbtremove}
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

% TO DO: Do some caching

% Output structure definition.
% Effectively, it describes a ADT tree.
% .nodes, .children, .parents ale all arrays of the same length and the j-th
% node in the tree is desribed by wt.nodes{j}, wt.children{j} and
% wt.parents(j). wt.nodes{j} is the actual data stored in the tree node
% (a structure returned form fwtinit) and wt.parents(j) and wt.children{j}
% define relationship to other nodes. wt.parents(j) is an index of the
% parent in the arrays. wt.children{j} is an array of indexes of the
% children nodes.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
wt.nodes = {};
wt.children = {};
wt.parents = [];
wt.freqOrder = 0;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
info.istight = 0;

% return empty struct if no argument was passed
if(nargin<1)
    return;
end


do_strict = 0;
do_dual = 0;

% Check 'strict'
if iscell(wtdef) && ischar(wtdef{1}) && strcmpi(wtdef{1},'strict')
   do_strict = 1;
   wtdef = wtdef{2:end};
end
% Check 'dual'
if iscell(wtdef) && ischar(wtdef{1}) && strcmpi(wtdef{1},'dual')
   do_dual = 1;
   wtdef = wtdef{2:end};
end

definput.import = {'wfbtcommon'};
[flags,kv]=ltfatarghelper({},definput,varargin);

% If wtdef is already a structure
if (isstruct(wtdef)&&isfield(wtdef,'nodes'))
    if isempty(wtdef.nodes)
        error('%s: The tree struct is empty.',upper(mfilename));
    end
    
    wt = wtdef;

    if do_dual || do_strict
       nodesArg = wt.nodes;
       if do_dual
          nodesArg = cellfun(@(nEl) {'dual',nEl},nodesArg,'UniformOutput',0);
       end
       if do_strict
          nodesArg = cellfun(@(nEl) {'strict',nEl},nodesArg,'UniformOutput',0);
       end
       info.istight = 1;
       wt.nodes = {};
       for ii=1:numel(nodesArg)
        % wt.nodes = cellfun(@(nEl) fwtinit(nEl),nodesArg,'UniformOutput',0);
          [wt.nodes{ii},infotmp] = fwtinit(nodesArg{ii});
          if info.istight
              info.istight = infotmp.istight;
          end
       end
       % Do the filter frequency shuffling again, since the filters were
       % overwritten in fwtinit.
       if wt.freqOrder
          wt = nat2freqOrder(wt);
       end
    end

    % Do filter shuffling if flags.do_freq differs from the wt.freqOrder.
    % Frequency and natural oreding coincide for DWT.
    if wt.freqOrder ~= flags.do_freq
       wt = nat2freqOrder(wt);
       wt.freqOrder = ~wt.freqOrder;
    end
    return;
end

% break if the input parameter is not in the correct format
if ~(iscell(wtdef)) || isempty(wtdef)
    error('%s: Unsupported filterbank tree definition.',upper(mfilename));
end

% Creating new tree
% Now wtdef is this {w,J,flag}
wdef = wtdef{1};
definput = [];
definput.flags.treetype = {'full','dwt','doubleband','quadband',...
                           'octaband','root'};
definput.keyvals.mod = [];
definput.keyvals.overcomplete = [];
definput.keyvals.J = [];
[flags2,kv2,J]=ltfatarghelper({'J'},definput,wtdef(2:end));

complainif_notposint(J,'J');

if do_dual
   wdef = {'dual',wdef};
end

if do_strict
   wdef = {'strict',wdef};
end

do_powshiftable = 0;
% Is the first level filterbank different?
if ~isempty(kv2.mod)
    if ischar(kv2.mod)
        if strcmpi(kv2.mod,'powshiftable')
           if ~flags2.do_dwt
              error('%s: powshiftable is only valid with the dwt flag.',...
                    upper(mfilename));
           end
           do_powshiftable = 1;
        else
           error('%s: Not recognized value for the mod key.',upper(mfilename));
        end
    else
        error('%s: Not recognized value for the first key.',upper(mfilename));
    end
end

if ~isempty(kv2.overcomplete)
     error('%s: TO DO: overcomplete.',upper(mfilename));
end


[w, info] = fwtinit(wdef);

% Doing one-node tree
if flags2.do_root
   J = 1;
end

if flags2.do_dwt
   % fill the structure to represent a DWT tree
   for jj=0:J-1
      wt = wfbtput(jj,0,w,wt);
   end
elseif flags2.do_full
   % fill the structure to represent a full wavelet tree
   for jj=0:J-1
     % for ii=0:numel(w.g)^(jj)-1
         wt = wfbtput(jj,0:numel(w.g)^(jj)-1,w,wt);
     % end
   end
elseif flags2.do_doubleband
   % fill the structure to represent a double band tree
   for jj=0:J-1
     % for ii=0:numel(w.g)^(jj)-1
         wt = wfbtput(2*jj,0,w,wt);
         wt = wfbtput(2*jj+1,0:1,w,wt);
     % end
   end

elseif flags2.do_quadband
   % fill the structure to represent a quad band tree
   for jj=0:J-1
     % for ii=0:numel(w.g)^(jj)-1
         wt = wfbtput(3*jj,0,w,wt);
         wt = wfbtput(3*jj+1,0:1,w,wt);
         wt = wfbtput(3*jj+2,0:3,w,wt);
     % end
   end
elseif flags2.do_octaband
   % fill the structure to represent a octa band tree
   for jj=0:J-1
     % for ii=0:numel(w.g)^(jj)-1
         wt = wfbtput(4*jj,0,w,wt);
         wt = wfbtput(4*jj+1,0:1,w,wt);
         wt = wfbtput(4*jj+2,0:3,w,wt);
         wt = wfbtput(4*jj+3,0:7,w,wt);
     % end
   end
end

% Do filter shuffling if frequency ordering is required,
wt.freqOrder = flags.do_freq;
if flags.do_freq
   wt = nat2freqOrder(wt);
end

if do_powshiftable
    % Change subsampling factors of the root to 1
    wt.nodes{wt.parents==0}.a(:) = 1;
end





