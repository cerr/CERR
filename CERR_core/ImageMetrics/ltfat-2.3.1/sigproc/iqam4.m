function xo=iqam4(xi)
%-*- texinfo -*-
%@deftypefn {Function} iqam4
%@verbatim
%IQAM4  Inverse QAM of order 4
%
%    IQAM4(xi) demodulates a signal mapping the input coefficients to the
%    closest complex root of unity, and returning the associated bit
%    pattern. This is the inverse operation of QAM4.
%
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/sigproc/iqam4.html}
%@seealso{qam4, demo_ofdm}
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

% Define the optimal ordering of bits
bitorder=[0;1;3;2];

% nbits is number of bits used. Everything will be ordered
% in groups of this size.
nbits=2;

symbols=length(xi);
L=symbols*nbits;

% We round the argument of the complex numbers to the closest root of
% unity of order 4
work=round(angle(xi)/(2*pi)*4);

% work now contains negative numbers. Get rid of these
work=mod(work,4);

% Reverse the optimal bit ordering.
reversebitorder=zeros(4,1);
reversebitorder(bitorder+1)=(0:3).';

% Apply the reverse ordering
work=reversebitorder(work+1);

xo=zeros(nbits,symbols);
% Reconstruct the bits
for bit=1:nbits
  xo(bit,:)=bitget(work,bit).';
end;

xo=xo(:);

