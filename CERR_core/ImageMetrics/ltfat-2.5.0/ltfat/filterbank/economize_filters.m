function [H,foff,L]=economize_filters(g,varargin)
% Compute 'econ' or 'asfreqfilter' type filter output from full length
% numerical filters
%
%   Url: http://ltfat.github.io/doc/filterbank/economize_filters.html

% Copyright (C) 2005-2022 Peter L. Soendergaard <peter@sonderport.dk> and others.
% This file is part of LTFAT version 2.5.0
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

definput.keyvals.efsuppthr = 10^(-5);
%definput.keyvals.bwthr = 10^(-3/10);

[flags,kv]=ltfatarghelper({},definput,varargin);

if iscell(g)
    g = cell2mat(g);
end

if any(isnan(g))
    error('%s: dual window could not be determined.',upper(mfilename));
end

L = size(g,1);
M = size(g,2);
H = cell(1,M);
foff = zeros(M,1);

idx = (0:L-1).';

for kk = 1:M
    gtemp = g(:,kk);
    abs_g = abs(gtemp);
    abs_g = abs_g./max(abs_g);
    
    % Find circular mean
    mean_g = .5*angle(sum(abs_g.*exp(2*pi*i.*idx./L)))/pi;
    mean_g = round(mod(mean_g,1)*L)+1;
    
    
    shift_g = floor(L/2) - mean_g;
    abs_g = circshift(abs_g,shift_g,1);
    efsupp_begin = find(abs_g > kv.efsuppthr,1,'first');
    efsupp_end = find(abs_g > kv.efsuppthr,1,'last');
    
    gtemp = circshift(gtemp,shift_g,1);
    H{kk} = gtemp(efsupp_begin:efsupp_end);
    
    foff(kk) = (efsupp_begin-1)-shift_g;
end

