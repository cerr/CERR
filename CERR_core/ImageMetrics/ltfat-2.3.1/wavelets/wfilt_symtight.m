function [h,g,a,info] = wfilt_symtight(K)
%-*- texinfo -*-
%@deftypefn {Function} wfilt_symtight
%@verbatim
%WFILT_SYMTIGHT Symmetric Nearly Shift-Invariant Tight Frame Wavelets
%
%   Usage: [h,g,a] = wfilt_symtight(K);
%
%   [h,g,a]=WFILT_SYMTIGHT(K) with K in {1,2} returns 4-band 
%   symmetric nearly shift-invariant tight framelets.
%
%
%
%   Examples:
%   ---------
%   :
%     wfiltinfo('symtight1');
%
%   :
%     wfiltinfo('symtight2');
% 
%   References:
%     A. F. Abdelnour and I. W. Selesnick. Symmetric nearly shift-invariant
%     tight frame wavelets. IEEE Transactions on Signal Processing,
%     53(1):231--239, 2005.
%     
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wfilt_symtight.html}
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
a = [2;2;2;2];

switch(K)
 case 1
    % Example 1. from the reference.   
    hlp = [
        -0.00055277114224  -0.00033767136406    
        -0.01132578895076   0.01854042113559
        -0.03673606302189  -0.02613107863916     
         0.00608048256466  -0.21256591159938 
         0.23533603943029  -0.12220989795770
         0.51430488230650   0.34270413842472
         0.51430488230650   0.34270413842472
         0.23533603943029  -0.12220989795770
         0.00608048256466  -0.21256591159938
        -0.03673606302189  -0.02613107863916
        -0.01132578895076   0.01854042113559
        -0.00055277114224  -0.00033767136406
    ];
 case 2 
    % Example 2. from the reference.   
    hlp = [
        -0.00006806716035   0.00033470718376
        -0.00052662487214  -0.00010709617646
        -0.00117716147891  -0.00083815645134
         0.00133411634276  -0.00184900827809
         0.01000587257073   0.00040715239482
         0.01000587257073   0.01797012314831
        -0.02668232685528   0.05528765033433
        -0.07024530947614   0.00398035279221
         0.00400234902829  -0.21067061941896
         0.26015268683895  -0.15449251248712
         0.52030537367790   0.28997740695853
         0.52030537367790   0.28997740695853
         0.26015268683895  -0.15449251248712
         0.00400234902829  -0.21067061941896
        -0.07024530947614   0.00398035279221
        -0.02668232685528   0.05528765033433
         0.01000587257073   0.01797012314831
         0.01000587257073   0.00040715239482
         0.00133411634276  -0.00184900827809
        -0.00117716147891  -0.00083815645134
        -0.00052662487214  -0.00010709617646
        -0.00006806716035   0.00033470718376  
         ];
   
  otherwise
        error('%s: No such SYMTIGHT filters.',upper(mfilename)); 

end

harr = [hlp, ...
            (-1).^(0:size(hlp,1)-1).'.*hlp(:,2),...
            (-1).^(0:size(hlp,1)-1).'.*hlp(:,1)];

h=mat2cell(harr,size(harr,1),ones(1,size(harr,2)));
h=cellfun(@(hEl) struct('h',hEl(:),'offset',-numel(hEl)/2),h,'UniformOutput',0);

g = h;




