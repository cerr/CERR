function [AF,BF]=uwpfbtbounds(wt,varargin)
%-*- texinfo -*-
%@deftypefn {Function} uwpfbtbounds
%@verbatim
%UWPFBTBOUNDS Frame bounds of Undecimated WPFBT
%   Usage: fcond=uwpfbtbounds(wt,L);
%          [A,B]=uwpfbtbounds(wt,L);
%
%   UWPFBTBOUNDS(wt,L) calculates the ratio B/A of the frame bounds
%   of the undecimated wavelet packet filterbank specified by wt for a 
%   system of length L. The ratio is a measure of the stability of the 
%   system. 
%
%   [A,B]=uwfbtbounds(wt,L) returns the lower and upper frame bounds
%   explicitly. 
%
%   See WFBT for explanation of parameter wt.
%
%   Additionally, the function accepts the following flags:
%
%   'intsqrt'(default),'intnoscale', 'intscale'
%       The filters in the filterbank tree are scaled to reflect the
%       behavior of UWPFBT and IUWPFBT with the same flags.
%
%   'sqrt'(default),'noscale','scale'
%       The filters in the filterbank tree are scaled to reflect the
%       behavior of UWPFBT and IUWPFBT with the same flags.  
%              
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/deprecated/uwpfbtbounds.html}
%@seealso{uwpfbt, filterbankbounds}
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

warning('UWPFBTBOUNDS is deprecated. Instead, use WPFBTBOUNDS with appropriate flags');

complainif_notenoughargs(nargin,1,'UWPFBTBOUNDS');

definput.keyvals.L = [];
definput.flags.scaling={'sqrt','scale','noscale'};
definput.flags.interscaling = {'intsqrt', 'intscale', 'intnoscale'};
[flags,~,L]=ltfatarghelper({'L'},definput,varargin);

if nargout<2
   AF = wpfbtbounds(wt,L,flags.scaling,flags.interscaling);
elseif nargout == 2
   [AF, BF] = wpfbtbounds(wt,L,flags.scaling,flags.interscaling);
end

