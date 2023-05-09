function [h,g,a,info] = wfilt_optsyma(N)
%-*- texinfo -*-
%@deftypefn {Function} wfilt_optsyma
%@verbatim
%WFILT_OPTSYMA  Optimizatized Symmetric Self-Hilbertian Filters 
%
%   Usage: [h,g,a] = wfilt_optsyma(N);
%
%   [h,g,a]=wfiltdt_optsyma(N) with N in {1,2,3} returns filters
%   suitable with optimized symmetry suitable for for dual-tree complex 
%   wavelet transform tree A.
%
%   Examples:
%   ---------
%   :
%     wfiltinfo('optsyma3');
% 
%   References:
%     B. Dumitrescu, I. Bayram, and I. W. Selesnick. Optimization of
%     symmetric self-hilbertian filters for the dual-tree complex wavelet
%     transform. IEEE Signal Process. Lett., 15:146--149, 2008.
%     
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wfilt_optsyma.html}
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


info.istight = 1;
a = [2;2];

switch(N)
 case 1
    hlp = [
        -0.0023380687
         0.0327804569
        -0.0025090221
        -0.1187657989
         0.2327030100
         0.7845762950
         0.5558782330
         0.0139812814
        -0.0766273710
        -0.0054654533
         0
         0         
    ];
case 2
    % 
    hlp = [
         0.0001598067
         0.0000007274
         0.0235678740
         0.0015148138
        -0.0931304005
         0.2161894746
         0.7761070855
         0.5778162235
         0.0004024156
        -0.0884144581 
        0
        0
        0
        0
    ];

case 3
    hlp = [
         0.0017293259
        -0.0010305604
        -0.0128374477
         0.0018813576
         0.0359457035
        -0.0395271550
        -0.1048144141
         0.2663807401
         0.7636351894
         0.5651724402
         0.0101286691
        -0.1081211791
         0.0133197551
         0.0223511379
         0
         0
         0
         0
    ];

  otherwise
        error('%s: No such filters.',upper(mfilename)); 

end
    % numel(hlp) must be even
    offset = -(floor(numel(hlp)/2)); 
    range = (0:numel(hlp)-1) + offset;
    
    % Create the filters according to the reference paper.
    %
    % REMARK: The phase of the alternating +1 and -1 is crucial here.
    %         
    harr = [...
            hlp,...
            (-1).^(range).'.*flipud(hlp),...
            %flipud(hlp),...
            %(-1).^(range).'.*hlp,...
            ];
        

htmp=mat2cell(harr,size(harr,1),ones(1,size(harr,2)));

h = cellfun(@(hEl)struct('h',hEl,'offset',offset),htmp(1:2),...
                   'UniformOutput',0);
     
g = h;




