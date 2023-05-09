function c = ref_phaselock(c,a)
%-*- texinfo -*-
%@deftypefn {Function} ref_phaselock
%@verbatim
%REF_PHASELOCK  Phaselock Gabor coefficients
%   Usage:  c=phaselock(c,a);
%
%   phaselock(c,a) phaselocks the Gabor coefficients c. The coefficients
%   must have been obtained from a DGT with parameter a.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_phaselock.html}
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

%   AUTHOR:

M=size(c,1);
N=size(c,2);
L=N*a;
b=L/M;

TimeInd = (0:(N-1))*a;
FreqInd = (0:(M-1))*b;

phase = FreqInd'*TimeInd;
phase = exp(2*1i*pi*phase/L);

c=bsxfun(@times,c,phase);


