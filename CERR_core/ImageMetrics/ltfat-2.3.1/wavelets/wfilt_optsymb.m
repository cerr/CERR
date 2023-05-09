function [h,g,a,info] = wfilt_optsymb(N)
%-*- texinfo -*-
%@deftypefn {Function} wfilt_optsymb
%@verbatim
%WFILT_OPTSYMB  Optimizatized Symmetric Self-Hilbertian Filters 
%
%   Usage: [h,g,a] = wfilt_optsymb(N);
%
%   [h,g,a]=wfiltdt_optsymb(N) with N in {1,2,3} returns filters
%   suitable with optimized symmetry suitable for for dual-tree complex 
%   wavelet transform tree B.
%
%   Examples:
%   ---------
%   :
%     wfiltinfo('optsymb3');
% 
%   References:
%     B. Dumitrescu, I. Bayram, and I. W. Selesnick. Optimization of
%     symmetric self-hilbertian filters for the dual-tree complex wavelet
%     transform. IEEE Signal Process. Lett., 15:146--149, 2008.
%     
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wfilt_optsymb.html}
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


[ha,~,a,info] = wfilt_optsyma(N);


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

