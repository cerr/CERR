function [h,g,a,info] = wfilt_ddenb(N)
%-*- texinfo -*-
%@deftypefn {Function} wfilt_ddenb
%@verbatim
%WFILT_DDENB  Double-Density Dual-Tree DWT filters 
%
%   Usage: [h,g,a] = wfilt_ddenb(N);
%
%   [h,g,a]=WFILT_DDENB(N) with N in {1,2} returns filters suitable
%   for dual-tree double density complex wavelet transform tree A. 
%
%   Examples:
%   ---------
%   :
%     wfiltinfo('ddena1');
%
%   References:
%     I. Selesnick. The double-density dual-tree DWT. Signal Processing, IEEE
%     Transactions on, 52(5):1304--1314, May 2004.
%     
%     
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wfilt_ddenb.html}
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
a = [2;2;2];

switch(N)
 case 1
    % Example 1. from the reference. 
    harr = [
        0.0138231641  0.0003671189  0.0008108446
        0.1825175668  0.0048473455  0.0107061875
        0.5537956151  0.0129572726  0.0264224754
        0.6403205201 -0.0061082309 -0.0424847245
        0.2024025378 -0.0656840149 -0.2095602589
       -0.1327035751 -0.0968519623 -0.0055184660
       -0.0714378446 -0.0211208454  0.6504107366
        0.0179754457  0.5492354832 -0.4735663386
        0.0085233088 -0.4154148634  0.0427795440
       -0.0010031763  0.0377726968  0
    ];
    d = [-3,-7,-7];
case 2
    % Example 2. From the reference. 
    harr = [
         0.0016678785  0.0000019623  0.0000067421
         0.0427009907  0.0000502404  0.0001726122
         0.2319241351  0.0002359631  0.0007854598
         0.5459409911 -0.0003026422 -0.0016861130
         0.6090383368 -0.0044343824 -0.0181424716
         0.2145936637 -0.0123017187 -0.0350847982
        -0.1629587558 -0.0156330903  0.0180629832
        -0.1283958243  0.0044955076  0.1356963431
         0.0309676536  0.0781684245  0.0980877181
         0.0373820215  0.1319270081 -0.1963413775
        -0.0038525812 -0.1244353736 -0.3762491967
        -0.0053106600 -0.4465930970  0.5674107094
         0.0003304362  0.5772994700 -0.2017431422
         0.0001955983 -0.1972513705  0.0090245313
        -0.0000103221  0.0087730988  0         
    ];
    d = [-4,-12,-12];

  otherwise
        error('%s: No such filters.',upper(mfilename)); 

end

htmp=mat2cell(harr,size(harr,1),ones(1,size(harr,2)));

h = cellfun(@(hEl,dEl)struct('h',hEl,'offset',dEl),...
                 htmp(1:3),num2cell(d(1:3)),...
                 'UniformOutput',0);
g = h;





