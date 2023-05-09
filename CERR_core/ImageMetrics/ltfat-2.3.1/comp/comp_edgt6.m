function cout=comp_edgt6(cin,a)
%-*- texinfo -*-
%@deftypefn {Function} comp_edgt6
%@verbatim
%COMP_EDGT6   Compute Even DGT type 6
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_edgt6.html}
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

M=size(cin,1);
N=size(cin,2)/2;
W=size(cin,3);

cout=zeros(M,N,W,assert_classname(cin));

cout=cin(:,1:N,:);

cout=reshape(cout,M*N,W);


