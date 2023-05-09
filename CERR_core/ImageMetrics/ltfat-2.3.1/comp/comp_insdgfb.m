function fr = comp_insdgfb(c,g,shift,Ls,dual)
%-*- texinfo -*-
%@deftypefn {Function} comp_insdgfb
%@verbatim
%COMP_INSDGFB  Non-stationary Gabor filterbank synthesis
%   Usage: fr = comp_insdgfb(c,g,shift,Ls,dual)
%          fr = comp_insdgfb(c,g,shift,Ls)
%          fr = comp_insdgfb(c,g,shift)
%
%   Input parameters: 
%         c         : Transform coefficients (matrix or cell array)
%         g         : Cell array of Fourier transforms of the analysis 
%                     windows
%         shift     : Vector of frequency shifts
%         Ls        : Original signal length (in samples)
%         dual      : Synthesize with the dual frame
%   Output parameters:
%         fr        : Synthesized signal (Channels are stored in the 
%                     columns)
%
%   Given the cell array c of non-stationary Gabor coefficients, and a 
%   set of filters g and frequency shifts shift this function computes 
%   the corresponding non-stationary Gabor filterbank synthesis.
%
%   If dual is set to 1 (default), an attempt is made to compute the 
%   canonical dual frame for the system given by g, shift and the size 
%   of the vectors in c. This provides perfect reconstruction in the 
%   painless case, see the references for more information.
% 
% 
%   References:
%     P. Balazs, M. Doerfler, F. Jaillet, N. Holighaus, and G. A. Velasco.
%     Theory, implementation and applications of nonstationary Gabor frames.
%     J. Comput. Appl. Math., 236(6):1481--1496, 2011.
%     
%     N. Holighaus, M. Doerfler, G. A. Velasco, and T. Grill. A framework for
%     invertible, real-time constant-Q transforms. IEEE Transactions on
%     Audio, Speech and Language Processing, 21(4):775 --785, 2013.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_insdgfb.html}
%@seealso{cqt, icqt, erblett, ierblett}
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

% Author: Nicki Holighaus
% Date: 10.04.13

%% Check input arguments
if nargin < 5
    dual = 1;
    if nargin < 3
        error('Not enough input arguments');
    end
end

if iscell(c) == 0 % If matrix format coefficients were used, convert to
    % cell
    [M,N,CH] = size(c);
    c = reshape(c,N*M,CH);
    c = mat2cell(c,M*ones(N,1),CH);
else
    N = length(c);
    CH = size(c{1},2);
    M = cellfun(@(x) size(x,1),c);
end

timepos = cumsum(shift);        % Calculate positions from shift vector
NN = timepos(end);              % Reconstruction length before truncation
timepos = timepos-shift(1);     % Adjust positions

fr = zeros(NN,CH,assert_classname(c{1},g{1})); % Initialize output

if nargin < 4
    Ls = NN; % If original signal length is not given do not truncate
end

if dual == 1 % Attempt to compute canonical dual frame
    g = nsgabdual(g,shift,M,Ls);
end

%% The overlap-add procedure including multiplication with the synthesis
% windows

if numel(M) == 1
    M = M*ones(N,1);
end

for ii = 1:N
    Lg = length(g{ii});
    
    win_range = mod(timepos(ii)+(-floor(Lg/2):ceil(Lg/2)-1),NN)+1;
    
    temp = fft(c{ii})*M(ii);
    temp = temp(mod([end-floor(Lg/2)+1:end,1:ceil(Lg/2)]-1,M(ii))+1,:);
    
    fr(win_range,:) = fr(win_range,:) + ...
        bsxfun(@times,temp,g{ii}([Lg-floor(Lg/2)+1:Lg,1:ceil(Lg/2)]));
end

fr = ifft(fr);
fr = fr(1:Ls,:); % Truncate the signal to original length (if given)


