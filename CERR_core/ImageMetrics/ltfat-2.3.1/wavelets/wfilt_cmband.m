function [h,g,a,info] = wfilt_cmband(M)
%-*- texinfo -*-
%@deftypefn {Function} wfilt_cmband
%@verbatim
%WFILT_CMBAND  Generates M-Band cosine modulated wavelet filters
%   Usage: [h,g,a] = wfilt_cmband(M);
%
%   Input parameters:
%         M     : Number of channels.
%
%   [h,g,a]=WFILT_CMBAND(M) with Min {2,3,dots} returns smooth, 
%   1-regular cosine modulated M*-band wavelet filters according to the 
%   reference paper.
%   The length of the filters is 4M.
%
%   Examples:
%   ---------
%   :
%     wfiltinfo('cmband3');
%
%   :
%     wfiltinfo('cmband4');
%
%   :
%     wfiltinfo('cmband5');
%
%
%   References:
%     R. Gopinath and C. Burrus. On cosine-modulated wavelet orthonormal
%     bases. Image Processing, IEEE Transactions on, 4(2):162--176, Feb 1995.
%     
%     
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wfilt_cmband.html}
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

% if K<1 || rem(K,1) ~= 0
%     error('%s: Regularity K has to be at least 1.',upper(mfilename));
% end

if M<2 || rem(M,1) ~= 0
    error('%s: Number of channels M has to be at least 2.',upper(mfilename));
end

h = cell(M,1);

if 0
    N = 2*M;
    n=0:N-1;
    p = sin(pi*(2*n+1)/(2*N));
    for m=0:M-1
        c = zeros(1,N);
        for n=0:N-1
            c(n+1) = cos(pi*(2*m+1)*(n-(2*M-1)/2)/(2*M)+(-1)^m*pi/4);
        end
        h{m+1} = p.*c;
    end
    scal = sqrt(M)/sum(h{1});
    h = cellfun(@(hEl) hEl*scal,h,'UniformOutput',0);
else
    N = 4*M;
    gamma = 0.4717 + exp(-0.00032084024272*M^3 + 0.01619976915653*M^2 - ...
            0.39479347799199*M - 2.24633148545678);
    beta = zeros(1,M);
    for n=0:M-1
        beta(n+1) = gamma + n*(pi-4*gamma)/(2*(M-1));
    end
    beta = repmat([beta, beta(end:-1:1)],1,2);
    n=0:N-1;
    p = sqrt(1/(2*M))*(cos(beta)- cos(pi*(2*n+1)/(4*M)) );
    
    for m=0:M-1
        c = zeros(1,N);
        for n=0:N-1
            c(n+1) = cos(pi*(2*m+1)*(n-(2*M-1)/2)/(2*M)+(-1)^m*pi/4);
        end
        h{m+1} = p.*c;
    end
    scal = sqrt(M)/sum(h{1});
    h = cellfun(@(hEl) hEl*scal,h,'UniformOutput',0);
end

h = cellfun(@(gEl) struct('h',gEl,'offset',-floor((length(gEl))/2)),h,'UniformOutput',0);
g = h;
info.istight = 1;
a = M*ones(M,1);


