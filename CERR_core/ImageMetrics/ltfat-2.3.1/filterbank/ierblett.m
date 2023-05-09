function fr = ierblett(c,g,shift,Ls,dual)
%-*- texinfo -*-
%@deftypefn {Function} ierblett
%@verbatim
%IERBLETT  ERBlet non-stationary Gabor synthesis
%   Usage: fr = ierblett(c,g,shift,Ls,dual)
%          fr = ierblett(c,g,shift,Ls)
%          fr = ierblett(c,g,shift)
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
%   Given the cell array c of non-stationary Gabor coefficients, and a 
%   set of filters g and frequency shifts shift this function computes 
%   the corresponding ERBlet synthesis.
%
%   If dual is set to 1 (default), an attempt is made to compute the 
%   canonical dual frame for the system given by g, shift and the size 
%   of the vectors in c. This provides perfect reconstruction in the 
%   painless case, see the references for more information.
%
% 
%   References:
%     T. Necciari, P. Balazs, N. Holighaus, and P. L. Soendergaard. The ERBlet
%     transform: An auditory-based time-frequency representation with perfect
%     reconstruction. In Proceedings of the 38th International Conference on
%     Acoustics, Speech, and Signal Processing (ICASSP 2013), pages 498--502,
%     Vancouver, Canada, May 2013. IEEE.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/filterbank/ierblett.html}
%@seealso{erblett}
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

if ~exist('dual','var')
    dual = 1;
end

fr = comp_insdgfb(c,g,shift,Ls,dual);

