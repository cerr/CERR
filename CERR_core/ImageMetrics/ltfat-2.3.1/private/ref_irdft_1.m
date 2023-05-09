function f=ref_irdft_1(c)
%-*- texinfo -*-
%@deftypefn {Function} ref_irdft_1
%@verbatim
%REF_RDFT_1  Reference IRDFT by IFFT
%   Usage:  f=ref_irdft(c);
%
%   Compute IRDFT by doubling the signal and doing an IDFT
%   to obtain the reconstructed signal
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_irdft_1.html}
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
Lhalf=ceil(L/2);
Lend=Lhalf*2-1;

if ~isreal(c)
  f=ref_irdft_1(real(c))+i*ref_irdft_1(imag(c));
else
  % Make it an orthonal transform.
  c=c*sqrt(L/2);
  
  cc=zeros(size(c),assert_classname(c));
  
  % Copy the first coefficient, it is real
  cc(1,:)=c(1,:)*sqrt(2);
  
  cc(2:Lhalf,:)=c(2:2:Lend,:)- i*c(3:2:Lend,:);
  cc(L-Lhalf+2:end,:)= c(Lend-1:-2:2,:)  +i*c(Lend:-2:3,:);

  % If f has an even length, we must also copy the Nyquest-wave
  % (it is real)
  if mod(L,2)==0
    cc(L/2+1,:)=c(end,:)*sqrt(2);
  end;

  f=real(ifft(cc));
end;








