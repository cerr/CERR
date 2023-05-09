function [g,a] = wpfbt2filterbank( wt, varargin)
%-*- texinfo -*-
%@deftypefn {Function} wpfbt2filterbank
%@verbatim
%WPFBT2FILTERBANK  WPFBT equivalent non-iterated filterbank
%   Usage: [g,a] = wpfbt2filterbank(wt)
%
%   Input parameters:
%         wt : Wavelet filter tree definition
%
%   Output parameters:
%         g   : Cell array containing filters
%         a   : Vector of sub-/upsampling factors
%
%   WPFBT2FILTERBANK(wt) calculates the impulse responses g and the
%   subsampling factors a of non-iterated filterbank, which is equivalent
%   to the wavelet packet filterbank tree described by wt. The returned
%   parameters can be used directly in FILTERBANK, UFILTERBANK or
%   FILTERBANK.
%
%   Please see help on WFBT for description of wt. The function
%   additionally support the following flags:
%
%   'freq'(default),'nat'
%      The filters are ordered to produce subbands in the same order as 
%      WPFBT with the same flag.
%
%   'intsqrt'(default),'intnoscale', 'intscale'
%      The filters in the filterbank tree are scaled to reflect the
%      behavior of WPFBT and IWPFBT with the same flags.
%
%   'scaling_notset'(default),'noscale','scale','sqrt'
%     Support for scaling flags as described in UWPFBT. By default,
%     the returned filterbank g and a is equivalent to WPFBT,
%     passing any of the non-default flags results in a filterbank 
%     equivalent to UWPFBT i.e. scaled and with a(:)=1.
%
%   Examples:
%   ---------
%
%   The following two examples create a multirate identity filterbank
%   using a tree of depth 3. In the first example, the filterbank is
%   identical to the DWT tree:
%
%     [g,a] = wpfbt2filterbank({'db10',3,'dwt'});
%     filterbankfreqz(g,a,1024,'plot','linabs','posfreq');
%
%
%   In the second example, the filterbank is identical to the full
%   wavelet tree:
%
%     [g,a] = wpfbt2filterbank({'db10',3,'full'});
%     filterbankfreqz(g,a,1024,'plot','linabs','posfreq');
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wpfbt2filterbank.html}
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


complainif_notenoughargs(nargin,1,'WPFBT2FILTERBANK');

definput.import = {'wfbtcommon','uwfbtcommon'};
definput.importdefaults = {'scaling_notset'};
definput.flags.interscaling={'intsqrt','intnoscale','intscale'};
[flags]=ltfatarghelper({},definput,varargin);

% build the tree
wt = wfbtinit({'strict',wt},flags.forder);

wt = comp_wpfbtscale(wt,flags.interscaling);

nIdx = nodesLevelsBForder(wt);
% Now we need to walk the tree by levels
g = {};
a = [];
for ii=1:numel(nIdx)
    rangeLoc = cellfun(@(eEl) 1:numel(eEl.h),wt.nodes(nIdx{ii}),...
                       'UniformOutput',0);
    rangeOut = cellfun(@(eEl) numel(eEl.h),wt.nodes(nIdx{ii}));
    rangeOut = mat2cell(1:sum(rangeOut),1,rangeOut);
    [gtmp,atmp] = nodesMultid(nIdx{ii},rangeLoc,rangeOut,wt);
    g(end+1:end+numel(gtmp)) = gtmp;
    a(end+1:end+numel(atmp)) = atmp;
end
g = g(:);
a = a(:);

if ~flags.do_scaling_notset
   g = comp_filterbankscale(g,a,flags.scaling);
   a = ones(numel(g),1);
end


function nodesIdxs = nodesLevelsBForder(treeStruct)


%find root
nodeNo = find(treeStruct.parents==0);
toGoTrough = [nodeNo];
nodesIdxs = {nodeNo};
inLevel = [1];
counter = 0;
level = 2;
chIdxSum = 0;
while ~isempty(toGoTrough)
   chtmp = find(treeStruct.children{toGoTrough(1)}~=0);
   chIdxtmp = treeStruct.children{toGoTrough(1)}(chtmp);
   counter = counter + 1;

   if(length(nodesIdxs)<level&&~isempty(chIdxtmp))
       nodesIdxs = {nodesIdxs{:},[]}; 
   end
   
   chIdxSum = chIdxSum + length(chIdxtmp);
   if(~isempty(chIdxtmp))
       nodesIdxs{level} = [nodesIdxs{level},chIdxtmp];
   end
   
   toGoTrough = [toGoTrough(2:end),chIdxtmp];

   if(counter==inLevel(level-1))
       counter = 0;
       inLevel(level) = chIdxSum;
       level = level + 1;
       chIdxSum = 0;
   end
end





















