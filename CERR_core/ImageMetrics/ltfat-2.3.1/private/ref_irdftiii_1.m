function f=ref_irdftiii_1(c)
%-*- texinfo -*-
%@deftypefn {Function} ref_irdftiii_1
%@verbatim
%REF_RDFTIII_1  Reference IRDFTIII by IDFTIII
%   Usage:  f=ref_irdftiii(c);
%
%   Only works for real functions.
%
%   Compute IRDFT by doubling the signal and doing an IDFTIII
%   to obtain the reconstructed signal
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_irdftiii_1.html}
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

L=size(c,1);
Lhalf=floor(L/2);
Lend=Lhalf*2;


cc=zeros(size(c));

cc(1:Lhalf,:)=(c(1:2:Lend,:)- i*c(2:2:Lend,:))/sqrt(2);
cc(L-Lhalf+1:end,:)= (c(Lend-1:-2:1,:)  +i*c(Lend:-2:2,:))/sqrt(2);

% If f has an even length, we must also copy the Nyquest-wave
% (it is real)
if mod(L,2)==1
  cc((L+1)/2,:)=c(L,:);
end;

f=real(ref_idftiii(cc));









