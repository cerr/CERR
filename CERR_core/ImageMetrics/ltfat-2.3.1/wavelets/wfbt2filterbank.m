function [g,a] = wfbt2filterbank( wt, varargin)
%-*- texinfo -*-
%@deftypefn {Function} wfbt2filterbank
%@verbatim
%WFBT2FILTERBANK  WFBT equivalent non-iterated filterbank
%   Usage: [g,a] = wfbt2filterbank(wt)
%
%   Input parameters:
%         wt : Wavelet filter tree definition
%
%   Output parameters:
%         g   : Cell array containing filters
%         a   : Vector of sub-/upsampling factors
%
%   [g,a]=WFBT2FILTERBANK(wt) calculates the impulse responses g and the
%   subsampling factors a of non-iterated filterbank, which is equivalent
%   to the wavelet filterbank tree described by wt used in WFBT. The 
%   returned parameters can be used directly in FILTERBANK and other routines.
%
%   [g,a]=WFBT2FILTERBANK({w,J,'dwt'}) does the same for the DWT (|FWT|)
%   filterbank tree.
%
%   Please see help on WFBT for description of wt and help on FWT for
%   description of w and J. 
%
%   The function additionally support the following flags:
%
%   'freq'(default),'nat'
%     The filters are ordered to produce subbands in the same order as 
%     WFBT with the same flag.
%
%   'scaling_notset'(default),'noscale','scale','sqrt'
%     Support for scaling flags as described in UWFBT. By default,
%     the returned filterbank g and a is equivalent to WFBT,
%     passing any of the non-default flags results in a filterbank 
%     equivalent to UWFBT i.e. scaled and with a(:)=1.
%
%   Examples:
%   ---------
%
%   The following two examples create a multirate identity filterbank
%   using a tree of depth 3. In the first example, the filterbank is
%   identical to the DWT tree:
%
%      [g,a] = wfbt2filterbank({'db10',3,'dwt'});
%      filterbankfreqz(g,a,1024,'plot','linabs','posfreq');
%
%   In the second example, the filterbank is identical to the full
%   wavelet tree:
%
%      [g,a] = wfbt2filterbank({'db10',3,'full'});
%      filterbankfreqz(g,a,1024,'plot','linabs','posfreq');
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wfbt2filterbank.html}
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

% AUTHOR: Zdenek Prusa


complainif_notenoughargs(nargin,1,'WFBT2FILTERBANK');

definput.import = {'uwfbtcommon', 'wfbtcommon'};
definput.importdefaults = {'scaling_notset'};
flags = ltfatarghelper({},definput,varargin);

% build the tree
wt = wfbtinit({'strict',wt},flags.forder);

% Pick just nodes with outputs
% wtPath = 1:numel(wt.nodes);
% wtPath(nodesOutputsNo(1:numel(wt.nodes),wt)==0)=[];
% 
% rangeLoc = nodesLocOutRange(wtPath,wt);
% rangeOut = nodesOutRange(wtPath,wt);

[nodesBF, rangeLoc, rangeOut] = treeBFranges(wt);
slice = ~cellfun(@isempty,rangeOut); % Limit to nodes with unconnected outputs
[g,a] = nodesMultid(nodesBF(slice),rangeLoc(slice),rangeOut(slice),wt);

if ~flags.do_scaling_notset
   g = comp_filterbankscale(g,a,flags.scaling);
   a = ones(numel(g),1);
end


