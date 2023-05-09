function c=ref_dft_1(f)
%-*- texinfo -*-
%@deftypefn {Function} ref_dft_1
%@verbatim
%REF_DFT_1  Reference DFT by doubling 
%   Usage:  c=ref_dft_1(f);
%
%   REF_DFT_1(f) computes a DFT of f by upsampling f and inserting zeros
%   at the odd positions.
%
%   This is not an efficient method, it is just meant to illustrate a 
%   symmetry of the DFT.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_dft_1.html}
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

flong=zeros(2*L,W,assert_classname(f));
flong(1:2:end-1)=f;

fflong=fft(flong)/sqrt(L);

c=fflong(1:L,:);



