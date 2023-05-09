function xo=qam4(xi)
%-*- texinfo -*-
%@deftypefn {Function} qam4
%@verbatim
%QAM4  Quadrature amplitude modulation of order 4
%   Usage:  xo=qam4(xi);
%
%   QAM4(xi) converts a vector of 0's and 1's into the complex roots of
%   unity (QAM4 modulation). Every 2 input coefficients are mapped into 1
%   output coefficient.
%
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/sigproc/qam4.html}
%@seealso{iqam4, demo_ofdm}
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

% Verify input

if ~all((xi==0) + (xi==1))
  error('Input vector must consist of only 0s and 1s');
end;

% Define the optimal ordering of bits
bitorder=[0;1;3;2];

% nbits is number of bits used. Everything will be ordered
% in groups of this size.
nbits=2;

L=length(xi);
symbols=L/nbits;

% nbits must divide L
if rem(symbols,1)~=0
  error('Length of input must be a multiple of 2');
end;

xi=reshape(xi,nbits,symbols);

two_power=(2.^(0:nbits-1)).';

% This could be vectorized by a repmat.
xo=zeros(symbols,1);
xo(:)=sum(bsxfun(@times,xi,two_power));

% xo now consist of numbers in the range 0:3
% Convert to the corresponding complex root of unity.
xo=exp(2*pi*i*bitorder(xo+1)/4);


