function c=ref_dftiv_1(f)
%-*- texinfo -*-
%@deftypefn {Function} ref_dftiv_1
%@verbatim
%REF_DFT_1  Reference DFTIV by quadrupling
%   Usage:  c=ref_dftii_1(f);
%
%   REF_DFTIV_1(f) computes a DFTIV of f by upsampling f and inserting zeros
%   at the even positions, and then doubling this signal
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_dftiv_1.html}
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

flong=zeros(4*L,W);
flong(2:2:2*L,:)=f;

fflong=fft(flong)/sqrt(L);

c=fflong(2:2:2*L,:);



