function cout=comp_irdgt(cin,a,M)
%-*- texinfo -*-
%@deftypefn {Function} comp_irdgt
%@verbatim
%COMP_IRDGT  Compute inverse real DGT.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_irdgt.html}
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

N=size(cin,1)/M;
W=size(cin,2);
L=N*a;

cin=reshape(cin,M,N,W);

Mhalf=ceil(M/2);
Mend=Mhalf*2-1;

cout=zeros(M,N,W,assert_classname(cin));

% Copy the first coefficient, it is real
cout(1,:,:)=cin(1,:,:);

cout(2:Mhalf,:,:)=(cin(2:2:Mend,:,:)- i*cin(3:2:Mend,:,:))/sqrt(2);
cout(M-Mhalf+2:M,:,:)= (cin(Mend-1:-2:2,:,:)  +i*cin(Mend:-2:3,:,:))/sqrt(2);

% If f has an even length, we must also copy the Nyquest-wave
% (it is real)
if mod(M,2)==0
  cout(M/2+1,:,:)=cin(M,:,:);
end;





