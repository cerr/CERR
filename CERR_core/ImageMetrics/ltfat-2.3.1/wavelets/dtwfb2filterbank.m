function [g,a,info] = dtwfb2filterbank( dualwt, varargin)
%-*- texinfo -*-
%@deftypefn {Function} dtwfb2filterbank
%@verbatim
%DTWFB2FILTERBANK DTWFB equivalent non-iterated filterbank
%   Usage: [g,a] = dtwfb2filterbank(dualwt)
%          [g,a,info] = dtwfb2filterbank(...)
%
%   Input parameters:
%      dualwt : Dual-tree wavelet filterbank specification.
%
%   Output parameters:
%      g      : Cell array of filters.
%      a      : Downsampling rate for each channel.
%      info   : Additional information.
%
%   [g,a] = DTWFB2FILTERBANK(dualwt) constructs a set of filters g and
%   subsampling factors a of a non-iterated filterbank, which is 
%   equivalent to the dual-tree wavelet filterbank defined by dualwt. 
%   The returned parameters can be used directly in FILTERBANK and other
%   routines. The format of dualwt is the same as in DTWFB and 
%   DTWFBREAL.  
%
%   The function internally calls DTWFBINIT and passes dualwt and all
%   additional parameters to it.
%
%   [g,a,info] = DTWFB2FILTERBANK(...) additionally outputs a info*
%   struct containing equivalent filterbanks of individual real-valued
%   trees as fields info.g1 and info.g2.
%
%   Additional parameters:
%   ----------------------
%
%   'real'
%      By default, the function returns a filtebank equivalent to DTWFB.
%      The filters can be restricted to cover only the positive frequencies
%      and to be equivivalent to DTWFBREAL by passing a 'real' flag. 
%
%   'freq'(default),'nat'
%     The filters are ordered to produce subbands in the same order as 
%     DTWFB or DTWFBREAL with the same flag.
%
%   Examples:
%   ---------
%
%   The following two examples create a multirate identity filterbank
%   using a duel-tree of depth 3:
%
%      [g,a] = dtwfb2filterbank({'qshift3',3},'real');
%      filterbankfreqz(g,a,1024,'plot','linabs');
%
%   In the second example, the filterbank is identical to the full
%   wavelet tree:
%
%      [g,a] = dtwfb2filterbank({'qshift3',3,'full'},'real');
%      filterbankfreqz(g,a,1024,'plot','linabs');
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/dtwfb2filterbank.html}
%@seealso{dtwfbinit}
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

complainif_notenoughargs(nargin,1,'DTWFB2FILTERBANK');

% Search for the 'real' flag
do_real = ~isempty(varargin(strcmp('real',varargin)));
if do_real
    %Remove the 'real' flag from varargin
    varargin(strcmp('real',varargin)) = [];
end

if ~isempty(varargin(strcmp('complex',varargin)))
    %Remove the 'complex' flag from varargin
    %It is not used elsewhere anyway
    varargin(strcmp('complex',varargin)) = [];
end


% Initialize the dual-tree
dtw = dtwfbinit({'strict',dualwt},varargin{:});

% Determine relation between the tree nodes
[wtPath, rangeLoc, rangeOut] = treeBFranges(dtw);
slice = ~cellfun(@isempty,rangeOut); % Limit to nodes with unconnected outputs
wtPath   = wtPath(slice); 
rangeLoc = rangeLoc(slice); 
rangeOut = rangeOut(slice);

% Multirate identity filters of the first tree
[g1,a] = nodesMultid(wtPath,rangeLoc,rangeOut,dtw);

% Multirate identity filters of the second tree
dtw.nodes = dtw.dualnodes;
g2 = nodesMultid(wtPath,rangeLoc,rangeOut,dtw);

if nargin>2
   % Return the filterbanks before doing the alignment
   info.g1 = cellfun(@(gEl) setfield(gEl,'h',gEl.h/2),g1,'UniformOutput',0);
   info.g2 = cellfun(@(gEl) setfield(gEl,'h',gEl.h/2),g2,'UniformOutput',0);
end

% Align filter offsets so they can be summed
for ii = 1:numel(g1)
   % Sanity checks
   assert(g1{ii}.offset<=0,sprintf('%s: Invalid wavelet filters.',upper(mfilename)));
   assert(g2{ii}.offset<=0,sprintf('%s: Invalid wavelet filters.',upper(mfilename)));
   
   % Insert zeros and update offsets
   offdiff = g1{ii}.offset-g2{ii}.offset;
   if offdiff>0
       g1{ii}.offset = g1{ii}.offset - offdiff;
       g1{ii}.h = [zeros(offdiff,1);g1{ii}.h(:)];
   elseif offdiff<0
       g2{ii}.offset = g2{ii}.offset + offdiff;
       g2{ii}.h = [zeros(-offdiff,1);g2{ii}.h(:)];
   end
   
   % Pad with zeros to a common length
   lendiff = numel(g1{ii}.h) - numel(g2{ii}.h);
   if lendiff~=0
       maxLen = max(numel(g1{ii}.h),numel(g2{ii}.h));
       g1{ii}.h = postpad(g1{ii}.h,maxLen);
       g2{ii}.h = postpad(g2{ii}.h,maxLen);
   end
end

% Filters covering the positive frequencies
g = cellfun(@(gEl,g2El) setfield(gEl,'h',(gEl.h+1i*g2El.h)/2),g1,g2,'UniformOutput',0);

% Mirror the filters when negative frequency filters are required too
if ~do_real
   gneg = cellfun(@(gEl,g2El) setfield(gEl,'h',(gEl.h-1i*g2El.h)/2),g1,g2,'UniformOutput',0);
   g = [g;gneg(end:-1:1)];
   a = [a;a(end:-1:1)];
end



