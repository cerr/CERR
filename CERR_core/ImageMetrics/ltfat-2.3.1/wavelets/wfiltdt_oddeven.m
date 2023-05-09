function [h,g,a,info] = wfiltdt_oddeven(N)
%-*- texinfo -*-
%@deftypefn {Function} wfiltdt_oddeven
%@verbatim
%WFILTDT_ODDEVEN  Kingsbury's symmetric odd and even filters
%
%   Usage: [h,g,a] = wfiltdt_oddeven(N);
%
%   [h,g,a]=wfilt_oddeven(N) with N in {1} returns the original odd
%   and even symmetric filters suitable for dual-tree complex wavelet
%   transform. The filters in individual trees are biorthogonal.
%
%   Examples:
%   ---------
%   :
%     wfiltdtinfo('ana:oddeven1');
% 
%   References:
%     N. Kingsbury. Complex wavelets for shift invariant analysis and
%     filtering of signals. Applied and Computational Harmonic Analysis,
%     10(3):234 -- 253, 2001.
%     
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wfiltdt_oddeven.html}
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


[h(:,1),g(:,1),a,info] = wfilt_oddevena(N);
[h(:,2),g(:,2)] = wfilt_oddevenb(N);
 
[info.defaultfirst, info.defaultfirstinfo] = fwtinit('oddevenb1');
[info.defaultleaf, info.defaultleafinfo] = ...
    deal(info.defaultfirst,info.defaultfirstinfo);



