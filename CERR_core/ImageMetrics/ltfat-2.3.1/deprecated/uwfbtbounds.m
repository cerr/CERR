function [AF,BF]=uwfbtbounds(wt,varargin)
%-*- texinfo -*-
%@deftypefn {Function} uwfbtbounds
%@verbatim
%UWFBTBOUNDS Frame bounds of Undecimated WFBT
%   Usage: fcond=uwfbtbounds(wt,L);
%          [A,B]=uwfbtbounds(wt,L);
%          [...]=uwfbtbounds(wt);
%
%   UWFBTBOUNDS(wt,L) calculates the ratio B/A of the frame bounds
%   of the undecimated filterbank specified by wt for a system of length
%   L. The ratio is a measure of the stability of the system.
%
%   UWFBTBOUNDS({w,J,'dwt'},L) calculates the ratio B/A of the frame
%   bounds of the undecimated DWT (|UFWT|) filterbank specified by w and
%   J for a system of length L.
%
%   UWFBTBOUNDS(wt) does the same thing, but L is the length of the 
%   longest filter in the identical filterbank.
%
%   [A,B]=UWFBTBOUNDS(...) returns the lower and upper frame bounds
%   explicitly.
%
%   See WFBT for explanation of parameter wt and FWT for explanation
%   of parameters w and J.
%
%   The function supports the following flags:
%
%   'sqrt'(default),'noscale','scale'
%       The filters in the filterbank tree are scaled to reflect the
%       behavior of UWFBT and IUWFBT with the same flags.  
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/deprecated/uwfbtbounds.html}
%@seealso{uwfbt, filterbankbounds}
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

warning('UWFBTBOUNDS is deprecated. Please use WFBTBOUNDS with a appropriate flag.');
complainif_notenoughargs(nargin,1,'UWFBTBOUNDS');

definput.keyvals.L = [];
definput.import = {'uwfbtcommon'};
[flags,~,L]=ltfatarghelper({'L'},definput,varargin);

if nargout<2
   AF = wfbtbounds(wt,L,flags.scaling);
elseif nargout == 2
   [AF,BF] = wfbtbounds(wt,L,flags.scaling);
end

