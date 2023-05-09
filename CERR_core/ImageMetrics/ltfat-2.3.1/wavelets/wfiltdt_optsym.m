function [h,g,a,info] = wfiltdt_optsym(N)
%-*- texinfo -*-
%@deftypefn {Function} wfiltdt_optsym
%@verbatim
%WFILTDT_OPTSYM  Optimizatized Symmetric Self-Hilbertian Filters 
%
%   Usage: [h,g,a] = wfiltdt_optsym(N);
%
%   [h,g,a]=WFILTDT_OPTSYM(N) with N in {1,2,3} returns filters
%   suitable for dual-tree complex wavelet transform with optimized 
%   symmetry.
%
%   Examples:
%   ---------
%   :
%     wfiltdtinfo('optsym3');
% 
%   References:
%     B. Dumitrescu, I. Bayram, and I. W. Selesnick. Optimization of
%     symmetric self-hilbertian filters for the dual-tree complex wavelet
%     transform. IEEE Signal Process. Lett., 15:146--149, 2008.
%     
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wfiltdt_optsym.html}
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

               
[h(:,1),g(:,1),a,info] = wfilt_optsyma(N);
[h(:,2),g(:,2)] = wfilt_optsymb(N);

% Default first and leaf filters
% They are chosen to be orthonormal near-symmetric here in order not to
% break the orthonormality of the overal representation.
[info.defaultfirst, info.defaultfirstinfo] = fwtinit('symorth1');
[info.defaultleaf, info.defaultleafinfo] = ...
    deal(info.defaultfirst,info.defaultfirstinfo);



