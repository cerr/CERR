function c=ref_dctiii_2(f)
%-*- texinfo -*-
%@deftypefn {Function} ref_dctiii_2
%@verbatim
%DCTII  Reference Discrete Consine Transform type III
%   Usage:  c=ref_dctiii_2(f);
%
%   The transform is real (only works for real input data) and
%   it is orthonormal.
%
%   The transform is computed as the exact inverse of DCTII, i.e. all
%   steps in the DCTII are reversed in order of computation.
%
%   NOT WORKING
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_dctiii_2.html}
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

R=1/sqrt(2)*[diag(exp((0:L-1)*pi*i/(2*L)));...
	     zeros(1,L); ...
	     [zeros(L-1,1),flipud(diag(exp(-(1:L-1)*pi*i/(2*L))))]];

R

R(1,1)=1;

c=real(R'*fft([f;flipud(f)])/sqrt(L)/2);



