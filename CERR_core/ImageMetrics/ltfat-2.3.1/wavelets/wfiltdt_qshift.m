function [h,g,a,info] = wfiltdt_qshift(N)
%-*- texinfo -*-
%@deftypefn {Function} wfiltdt_qshift
%@verbatim
%WFILTDT_QSHIFT  Improved Orthogonality and Symmetry properties 
%
%   Usage: [h,g,a] = wfiltdt_qshift(N);
%
%   [h,g,a]=WFILTDT_QSHIFT(N) with N in {1,2,3,4,5,6,7} returns 
%   Kingsbury's Q-shift filters suitable for dual-tree complex wavelet 
%   transform.
%   Filters in both trees are orthogonal and based on a single prototype
%   low-pass filter with a quarter sample delay. Other filters are
%   derived by modulation and time reversal such that they fulfil the
%   half-sample delay difference between the trees.   
%
%   Examples:
%   ---------
%   :
%     wfiltdtinfo('qshift3');
% 
%   References:
%     N. G. Kingsbury. A dual-tree complex wavelet transform with improved
%     orthogonality and symmetry properties. In ICIP, pages 375--378, 2000.
%     
%     N. Kingsbury. Design of q-shift complex wavelets for image processing
%     using frequency domain energy minimization. In Image Processing, 2003.
%     ICIP 2003. Proceedings. 2003 International Conference on, volume 1,
%     pages I--1013--16 vol.1, Sept 2003.
%     
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wfiltdt_qshift.html}
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


[h(:,1),g(:,1),a,info] = wfilt_qshifta(N);
[h(:,2),g(:,2)] = wfilt_qshiftb(N);

% Default first and leaf filters
% They are chosen to be orthonormal near-symmetric here in order not to
% break the orthonormality of the overal representation.
[info.defaultfirst, info.defaultfirstinfo] = fwtinit('symorth1');
[info.defaultleaf, info.defaultleafinfo] = ...
    deal(info.defaultfirst,info.defaultfirstinfo);



