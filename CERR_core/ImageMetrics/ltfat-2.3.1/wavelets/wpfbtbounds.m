function [AF,BF]=wpfbtbounds(wt,varargin)
%-*- texinfo -*-
%@deftypefn {Function} wpfbtbounds
%@verbatim
%WPFBTBOUNDS Frame bounds of WPFBT
%   Usage: fcond=wpfbtbounds(wt,L);
%          [A,B]=wpfbtbounds(wt,L);
%          [...]=wpfbtbounds(wt);
%
%   WPFBTBOUNDS(wt,L) calculates the ratio B/A of the frame bounds
%   of the wavelet packet filterbank specified by wt for a system of length
%   L. The ratio is a measure of the stability of the system.
%
%   WPFBTBOUNDS(wt) does the same, except L is chosen to be the next 
%   compatible length bigger than the longest filter from the identical
%   filterbank.
%
%   [A,B]=WPFBTBOUNDS(...) returns the lower and upper frame bounds
%   explicitly.
%
%   See WFBT for explanation of parameter wt. 
%
%   Additionally, the function accepts the following flags:
%
%   'intsqrt'(default),'intnoscale', 'intscale'
%       The filters in the filterbank tree are scaled to reflect the
%       behavior of WPFBT and IWPFBT with the same flags.
%
%   'scaling_notset'(default),'noscale','scale','sqrt'
%     Support for scaling flags as described in UWPFBT. By default,
%     the bounds are caltulated for WPFBT, passing any of the non-default
%     flags results in bounds for UWPFBT.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wpfbtbounds.html}
%@seealso{wpfbt, filterbankbounds}
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


complainif_notenoughargs(nargin,1,'WPFBTBOUNDS');

definput.keyvals.L = [];
definput.flags.interscaling = {'intsqrt', 'intscale', 'intnoscale'};
definput.import = {'uwfbtcommon'};
definput.importdefaults = {'scaling_notset'};
[flags,~,L]=ltfatarghelper({'L'},definput,varargin);

wt = wfbtinit({'strict',wt},'nat');

if ~isempty(L) && flags.do_scaling_notset
   if L~=wfbtlength(L,wt)
       error(['%s: Specified length L is incompatible with the length of ' ...
              'the time shifts.'],upper(mfilename));
   end;
end


for ii=1:numel(wt.nodes)
   a = wt.nodes{ii}.a;
   assert(all(a==a(1)),sprintf(['%s: One of the basic wavelet ',...
                                'filterbanks is not uniform.'],...
                                upper(mfilename)));
end

% Do the equivalent filterbank using multirate identity property
[gmultid,amultid] = wpfbt2filterbank(wt,flags.interscaling,flags.scaling);

if isempty(L)
   L = wfbtlength(max(cellfun(@(gEl) numel(gEl.h),gmultid)),wt);  
end

% Do the equivalent uniform filterbank
if any(amultid~=amultid(1))
   [gu,au] = nonu2ufilterbank(gmultid,amultid);
else
   [gu,au] = deal(gmultid,amultid);
end

if nargout<2
   AF = filterbankbounds(gu,au,L);
elseif nargout == 2
   [AF, BF] = filterbankbounds(gu,au,L);
end

