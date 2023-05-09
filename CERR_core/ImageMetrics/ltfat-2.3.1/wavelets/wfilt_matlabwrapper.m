function [h,g,a,info] = wfilt_matlabwrapper(wname)
%-*- texinfo -*-
%@deftypefn {Function} wfilt_matlabwrapper
%@verbatim
%WFILT_MATLABWRAPPER Wrapper of the Matlab Wavelet Toolbox wfilters function
%   Usage: [h,g,a] = wfilt_matlabwrapper(wname);
%
%   [h,g,a]=WFILT_MATLABWRAPPER(wname) calls Matlab Wavelet Toolbox
%   function wfilters and passes the parameter wname to it. 
%
%   This function requires the Matlab Wavelet Toolbox.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wfilt_matlabwrapper.html}
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

if ~exist('wfilters',2)
    error('%s: Matlab Wavelet Toolbox is not present.',upper(mfilename));
end

a = [2;2];
[lo,hi,lo_s,hi_s] = wfilters(wname);

h=cell(2,1);
h{1} = lo(:);
h{2} = hi(:);

g=cell(2,1);
g{1} = flipud(lo_s(:));
g{2} = flipud(hi_s(:));

if all(h{1}==g{1}) && all(h{2}==g{2})
  info.istight = 1;
else
  info.istight = 0; 
end

g = cellfun(@(gEl) struct('h',gEl(:),'offset',-numel(gEl)/2),g,'UniformOutput',0);
h = cellfun(@(hEl) struct('h',hEl(:),'offset',-numel(hEl)/2),h,'UniformOutput',0);

