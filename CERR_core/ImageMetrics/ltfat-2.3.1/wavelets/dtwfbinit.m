function [dualwt,info] = dtwfbinit(dualwtdef,varargin)
%-*- texinfo -*-
%@deftypefn {Function} dtwfbinit
%@verbatim
%DTWFBINIT Dual-Tree Wavelet Filterbank Initialization
%   Usage:  dualwt=dtwfbinit(dualwtdef);
%
%   Input parameters:
%         dualwtdef : Dual-tree filterbank definition.
%
%   Output parameters:
%         dualwt    : Dual-tree filtarbank structure.
%
%   dtwfinit() (a call without aguments) creates an empty structure. It
%   has the same fields as the struct. returned from WFBTINIT plus a field
%   to hold nodes from the second tree:
%
%      .nodes      Filterbank nodes of the first tree
% 
%      .dualnodes  Filterbank nodes of the second tree
%
%      .children   Indexes of children nodes
%
%      .parents    Indexes of a parent node
%
%      .forder     Frequency ordering of the resultant frequency bands.   
%
%   dtwfinit({dualw,J,flag}) creates a structure representing a dual-tree
%   wavelet filterbank of depth J, using dual-tree wavelet filters 
%   specified by dualw. The shape of the tree is controlled by flag.
%   Please see help on DTWFB or DTWFBREAL for description of the
%   parameters.
%
%   [dualwt,info]=dtwfinit(...) additionally returns info struct which
%   provides some information about the computed window:
%
%   info.tight
%      True if the overall tree construct a tight frame.
%
%   info.dw
%      A structure containing basic dual-tree filters as returned from
%      fwtinit(dualwtdef,'wfiltdt_').
%   
%   Additional optional flags
%   -------------------------
%
%   'freq','nat'
%      Frequency or natural ordering of the resulting coefficient subbands.
%      Default ordering is 'freq'.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/dtwfbinit.html}
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


% Output structure definition.
% The structure has the same fields as returned by wfbtinit
% but contains additional field .dualnodes containing
% filters of the dual tree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dualwt = wfbtinit();
dualwt.dualnodes = {};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
info.istight = 0;

if nargin < 1
    return;
end

% Frequency or natural ordering
definput.import = {'wfbtcommon'};
[flags,kv]=ltfatarghelper({},definput,varargin);

% Strict throws an error if filterbank is not tight and ana: or syn:
% is not specified.
do_strict = 0;
% Dual returns the 'other' filterbank. 
do_dual = 0;

% Check 'strict'
if iscell(dualwtdef) && ischar(dualwtdef{1}) && strcmpi(dualwtdef{1},'strict')
   do_strict = 1;
   dualwtdef = dualwtdef{2:end};
end
% Check 'dual'
if iscell(dualwtdef) && ischar(dualwtdef{1}) && strcmpi(dualwtdef{1},'dual')
   do_dual = 1;
   dualwtdef = dualwtdef{2:end};
end

% FIRST, check if dtwdef is already a struct
if isstruct(dualwtdef)
   if isfield(dualwtdef,'nodes') && isfield(dualwtdef,'dualnodes')
      dualwt = dualwtdef;
   
       if do_dual || do_strict
          nodesArg = dualwt.nodes;
          
          % Undo the frequency ordering
          if dualwt.freqOrder
             dualwt = nat2freqOrder(dualwt,'rev');
          end
          
          doDualTreeFilt = cellfun(@(nEl) strcmp(nEl.wprefix,'wfiltdt_'),...
                                   nodesArg);
        
          if do_dual
             nodesArg = cellfun(@(nEl) {'dual',nEl},nodesArg,...
                                'UniformOutput',0);
          end
          if do_strict
             nodesArg = cellfun(@(nEl) {'strict',nEl},nodesArg,...
                                'UniformOutput',0);
             
          end
          info.istight = 1;
          dualwt.nodes = {};
          dualwt.dualnodes = {};
      
         
          rangeRest = 1:numel(nodesArg);
          rangeRest(dualwt.parents==0) = []; 
                    
          for ii=rangeRest
              if doDualTreeFilt(ii)
                % This is dual-tree specific filterbank
                [dualwt.nodes{ii},infotmp] = fwtinit(nodesArg{ii},'wfiltdt_');
                dualwt.dualnodes{ii} = dualwt.nodes{ii};
                dualwt.nodes{ii}.h(:,2) = [];
                dualwt.nodes{ii}.g(:,2) = [];
                dualwt.dualnodes{ii}.h(:,1) = [];
                dualwt.dualnodes{ii}.g(:,1) = [];
              else
                [dualwt.nodes{ii},infotmp] = fwtinit(nodesArg{ii}); 
                dualwt.dualnodes{ii} = dualwt.nodes{ii};
              end
              info.istight = info.istight && infotmp.istight;
          end
          
          % Treat root separately
          [rootNode,infotmp] = fwtinit(nodesArg{dualwt.parents==0}); 
          dualwt = replaceRoots(dualwt,rootNode);
          info.istight = info.istight && infotmp.istight;
          
          % Do the filter frequency shuffling again, since the filters were
          % overwritten in fwtinit.
          if dualwt.freqOrder
             dualwt = nat2freqOrder(dualwt);
          end
       end

       % Do filter shuffling if flags.do_freq differs from the wt.freqOrder.
       % Frequency and natural oreding coincide for DWT.
       if dualwt.freqOrder && ~flags.do_freq
          dualwt = nat2freqOrder(dualwt,'rev');
          dualwt.freqOrder = ~dualwt.freqOrder;
       elseif ~dualwt.freqOrder && flags.do_freq
          dualwt = nat2freqOrder(dualwt);
          dualwt.freqOrder = ~dualwt.freqOrder;
       end   
   else
       error('%s: Invalid dual-tree structure format.',upper(mfilename));
   end
   return;
end

% Parse the other params
% Tree type
definput.flags.treetype = {'dwt','full','doubleband','quadband',...
                           'octaband','root'};
% First stage filterbank
definput.keyvals.first = [];
% Leaf filterbank
definput.keyvals.leaf = [];
% Depth of the tree
definput.keyvals.J = [];
wdef = dualwtdef{1};
[flags2,kv2,J]=ltfatarghelper({'J'},definput,dualwtdef(2:end));
complainif_notposint(J,'J');

% Now dtwdef is this {dtw,J,flag,'first',w}
if do_dual
   wdef = {'dual',wdef};
end
if do_strict
   wdef = {'strict',wdef};
end

if ~(ischar(wdef) || iscell(wdef))
    error('%s: Unrecognized format of dual-tree filters.',upper(mfilename));
end

% Get the dual-tree filters
[w, dtinfo] = fwtinit(wdef,'wfiltdt_');

info.istight = dtinfo.istight;
info.dw = w;

% Determine the first-stage wavelet filters
if ~isfield(dtinfo,'defaultfirst') && isempty(kv2.first)
    error('%s: No first stage wavelet filters specified.',upper(mfilename));
end


if ~isempty(kv2.first) 
   if do_dual
      kv2.first = {'dual',kv2.first};
   end
   if do_strict
      kv2.first = {'strict',kv2.first};
   end

   [kv2.first, firstinfo] = fwtinit(kv2.first);
   isfirsttight = firstinfo.istight;
else
   kv2.first = dtinfo.defaultfirst;
   isfirsttight = dtinfo.defaultfirstinfo.istight;
end



isleaftight = [];
if ~(flags2.do_dwt || flags2.do_root)
    % Determine leaf nodes (only valid for wavelet packets)
    if ~isfield(dtinfo,'defaultleaf') && isempty(kv2.leaf) 
        error('%s: No leaf wavelet filters specified.',...
              upper(mfilename));
    else
       if isempty(kv2.leaf)
          kv2.leaf = dtinfo.defaultleaf; 
          isleaftight = dtinfo.defaultleafinfo.istight;
       else
          if do_dual
             kv2.leaf = {'dual',kv2.leaf};
          end
          if do_strict
             kv2.leaf = {'strict',kv2.leaf};
          end
          [kv2.leaf, leafinfo] = fwtinit(kv2.leaf);
          isleaftight = leafinfo.istight;
       end
    end
end


% Extract filters for dual trees
% This is a bit clumsy...
w1 = w;
w1.h = w1.h(:,1);
w1.g = w1.g(:,1);

w2 = w;
w2.h = w2.h(:,2);
w2.g = w2.g(:,2);


% Initialize both trees
dualwt  = wfbtinit({w1,J,flags2.treetype}, 'nat');
dtw2 = wfbtinit({w2,J,flags2.treetype}, 'nat');
% Merge tree definitions to a single struct.
dualwt.dualnodes = dtw2.nodes;
dualwt = replaceRoots(dualwt,kv2.first);


% Replace the 'packet leaf nodes' (see Bayram)
if ~(flags2.do_dwt || flags2.do_root)
    filtNo = numel(w1.g);
    if flags2.do_doubleband 
       for jj=1:J-1
         dualwt = wfbtput(2*(jj+1)-1,1:filtNo-1,kv2.leaf,dualwt,'force');
       end
    elseif flags2.do_quadband
       idx = 1:filtNo-1;
       idx = [idx,idx+filtNo];
       dualwt = wfbtput(2,idx,kv2.leaf,dualwt,'force');
       for jj=1:J-1
         dualwt = wfbtput(3*(jj+1)-2,1:filtNo-1,kv2.leaf,dualwt,'force');
         dualwt = wfbtput(3*(jj+1)-1,1:2*filtNo-1,kv2.leaf,dualwt,'force');
       end 
    elseif flags2.do_octaband
       idx = 1:filtNo-1;idx = [idx,idx+filtNo];
       dualwt = wfbtput(2,idx,kv2.leaf,dualwt,'force');
       idx = 1:2*filtNo-1;idx = [idx,idx+2*filtNo];
       dualwt = wfbtput(3,idx,kv2.leaf,dualwt,'force');
       for jj=1:J-1
         dualwt = wfbtput(4*(jj+1)-3,1:filtNo-1,kv2.leaf,dualwt,'force');
         dualwt = wfbtput(4*(jj+1)-2,1:2*filtNo-1,kv2.leaf,dualwt,'force');
         dualwt = wfbtput(4*(jj+1)-1,1:4*filtNo-1,kv2.leaf,dualwt,'force');
       end 
    elseif flags2.do_full
       for jj=2:J-1
          idx = 1:filtNo^jj-1;
          idx(filtNo^(jj-1))=[];
          dualwt = wfbtput(jj,idx,kv2.leaf,dualwt,'force');
       end 
    else
        error('%s: Something is seriously wrong!',upper(mfilename));
    end 
end


% Do filter shuffling if frequency ordering is required,
dualwt.freqOrder = flags.do_freq;
if flags.do_freq
   dualwt = nat2freqOrder(dualwt); 
end

% 
info.istight = isfirsttight && info.istight;
if ~isempty(isleaftight)
   info.istight = info.istight && isleaftight;
end


function dtw = replaceRoots(dtw,rootNode)
% Replace the root nodes

firstTmp = rootNode;
firstTmp.h = cellfun(@(hEl) setfield(hEl,'offset',hEl.offset+1),...
                        firstTmp.h,'UniformOutput',0);
firstTmp.g = cellfun(@(gEl) setfield(gEl,'offset',gEl.offset+1),...
                        firstTmp.g,'UniformOutput',0);
                 
% First tree root 
dtw.nodes{dtw.parents==0} = rootNode;  
% Second tree root (shifted by 1 sample)
dtw.dualnodes{dtw.parents==0} = firstTmp;  




