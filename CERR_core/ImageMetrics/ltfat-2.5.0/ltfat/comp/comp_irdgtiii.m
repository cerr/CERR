function cout=comp_irdgtiii(cin,a,M)
%COMP_IRDGTIII  Compute inverse real DGT type III.
% 
%   This is a computational routine. Do not call it
%   directly.
%
%   Url: http://ltfat.github.io/doc/comp/comp_irdgtiii.html

% Copyright (C) 2005-2022 Peter L. Soendergaard <peter@sonderport.dk> and others.
% This file is part of LTFAT version 2.5.0
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

%   AUTHOR : Peter L. Søndergaard

N=size(cin,1)/M;
W=size(cin,2);
L=N*a;

cin=reshape(cin,M,N,W);

Mhalf=floor(M/2);

cout=zeros(M,N,W,assert_classname(cin));

for m=0:Mhalf-1
  cout(m+1,:,:)=1/sqrt(2)*(cin(2*m+1,:,:)-i*cin(2*m+2,:,:));
  cout(M-m,:,:)=1/sqrt(2)*(cin(2*m+1,:,:)+i*cin(2*m+2,:,:));
end;

if mod(M,2)==1
  cout((M+1)/2,:,:)=cin(M,:,:);
end;






