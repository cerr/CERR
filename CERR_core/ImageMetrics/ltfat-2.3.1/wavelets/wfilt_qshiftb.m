function [h,g,a,info] = wfilt_qshiftb(N)
%-*- texinfo -*-
%@deftypefn {Function} wfilt_qshiftb
%@verbatim
%WFILT_QSHIFTB  Improved Orthogonality and Symmetry properties 
%
%   Usage: [h,g,a] = wfilt_qshiftb(N);
%
%   [h,g,a]=WFILT_QSHIFTB(N) with N in {1,2,3,4,5,6,7} returns
%   Kingsbury's Q-shift wavelet filters for tree B.
%
%   Examples:
%   ---------
%   :
%     figure(1);
%     wfiltinfo('qshiftb3');
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
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wfilt_qshiftb.html}
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

[ha,~,a,info] = wfilt_qshifta(N);

hlp = ha{1}.h;
offset = -(numel(hlp)/2); 
range = (0:numel(hlp)-1) + offset;
    
% Create the filters according to the reference paper.
%
% REMARK: The phase of the alternating +1 and -1 is crucial here.
%         
    harr = [...
            flipud(hlp),...
            (-1).^(range).'.*hlp,...
            ];
        

htmp=mat2cell(harr,size(harr,1),ones(1,size(harr,2)));

h(1:2,1) = cellfun(@(hEl)struct('h',hEl,'offset',offset),htmp(1:2),...
                   'UniformOutput',0);
g = h;




