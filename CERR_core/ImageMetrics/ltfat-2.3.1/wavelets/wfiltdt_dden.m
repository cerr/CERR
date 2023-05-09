function [h,g,a,info] = wfiltdt_dden(N)
%-*- texinfo -*-
%@deftypefn {Function} wfiltdt_dden
%@verbatim
%WFILTDT_DDEN  Double-Density Dual-Tree DWT filters 
%
%   Usage: [h,g,a] = wfiltdt_dden(N);
%
%   [h,g,a]=WFILTDT_DDEN(N) with N in {1,2} returns filters suitable
%   for dual-tree double density complex wavelet transform. 
%
%   Examples:
%   ---------
%   :
%     wfiltdtinfo('dden1');
%
%   :
%     wfiltdtinfo('dden2');
% 
%   References:
%     I. Selesnick. The double-density dual-tree DWT. Signal Processing, IEEE
%     Transactions on, 52(5):1304--1314, May 2004.
%     
%     
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wfiltdt_dden.html}
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

[h(:,1),g(:,1),a,info] = wfilt_ddena(N);
[h(:,2),g(:,2)] = wfilt_ddenb(N);

[info.defaultfirst, info.defaultfirstinfo] = fwtinit('symdden2');
[info.defaultleaf, info.defaultleafinfo] = ...
    deal(info.defaultfirst,info.defaultfirstinfo);





