function c=ref_edgtii_1(f,g,a,M)
%-*- texinfo -*-
%@deftypefn {Function} ref_edgtii_1
%@verbatim
%REF_EDGTII_1   Reference Even Discrete Gabor transform type II by DGT
%   Usage  c=ref_edgt(f,g,a,M);
%
%   If a is even, then the input window must be odd-centered of length 2L.
%   
%   If a is odd, then the input window must be even-centered of length 2L.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_edgtii_1.html}
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

L=size(f,1);
W=size(f,2);

N=L/a;

clong=ref_gdgt([f;conj(flipud(f))],g,a,M,.5,0,floor(a/2));

c=clong(1:M*N,:);



