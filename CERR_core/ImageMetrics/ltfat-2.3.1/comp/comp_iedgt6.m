function [cout]=comp_iedgt6(cin,a,M)
%-*- texinfo -*-
%@deftypefn {Function} comp_iedgt6
%@verbatim
%COMP_IEDGT6   Compute inverse even DGT type 6
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_iedgt6.html}
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

cout=zeros(M,2*N,W,assert_classname(cin));
cout(:,1:N,:)=cin;

% Copy the non modulated coefficients.
cout(1,N+1:2*N,:)=cin(1,N:-1:1,:);

% Copy the modulated coefficients.
cout(2:M,N+1:2*N,:)=-cin(M:-1:2,N:-1:1,:);




