function [h,g,a,info] = wfilt_mband(N)
%-*- texinfo -*-
%@deftypefn {Function} wfilt_mband
%@verbatim
%WFILT_MBAND  Generates 4-band coder
%   Usage: [h,g,a] = wfilt_mband(N);
%
%   [h,g,a]=WFILT_MBAND(1) returns linear-phase 4-band filters
%   from the reference.
%
%   The filters are not actually proper wavelet filters, because the
%   scaling filter is not regular, therefore it is not stable under 
%   iterations (does not converge to a scaling function). 
%   
%
%   Examples:
%   ---------
%   :
%
%     wfiltinfo('mband1');
%
%   References:
%     O. Alkin and H. Caglar. Design of efficient M-band coders with
%     linear-phase and perfect-reconstruction properties. Signal Processing,
%     IEEE Transactions on, 43(7):1579 --1590, jul 1995.
%     
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wfilt_mband.html}
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

a= [4;4;4;4];

switch(N)
case 1
harr = [
[ 0.036796442259
-0.024067904384
-0.064951364125
-0.042483542576
-0.030838286810
 0.174767766545
 0.409804433561
 0.540933249858
 0.540933249858
 0.409804433561
 0.174767766545
-0.030838286810
-0.042483542576
-0.064951364125
-0.024067904384
 0.036796442259
 ],...
 [
 0.024067904384
-0.036796442259
-0.042483542576
-0.064951364125
-0.174767766545
 0.030838286810
 0.540933249858
 0.409804433561
-0.409804433561
-0.540933249858
-0.030838286810
 0.174767766545
 0.064951364125
 0.042483542576
 0.036796442259
-0.024067904384
],...
[
 0.024067904384
 0.036796442259
-0.042483542576
 0.064951364125
-0.174767766544
-0.030838286810
 0.540933249858
-0.409804433561
-0.409804433561
 0.540933249858
-0.030838286810
-0.174767766545
 0.064951364125
-0.042483542576
 0.036796442259
 0.024067904384
],...
[ 
 0.036796442259
 0.024067904384
-0.064951364125
 0.042483542576
-0.030838286810
-0.174767766545
 0.409804433561
-0.540933249858
 0.540933249858
-0.409804433561
 0.174767766545
 0.030838286810
-0.042483542576
 0.064951364125
-0.024067904384
-0.036796442259
]
];

otherwise
        error('%s: No such M-Band filters.',upper(mfilename));
end

g=mat2cell(harr,size(harr,1),ones(1,size(harr,2)));
g=cellfun(@(gEl) struct('h',gEl,'offset',-numel(gEl)/2),g,'UniformOutput',0);
h = g;

info.istight = 1;

