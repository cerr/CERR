function c=ref_dsti_1(f)
%REF_DSTI_1  Reference Discrete Sine Transform type I
%   Usage:  c=ref_dsti_1(f);
%
%
%
%   Url: http://ltfat.github.io/doc/reference/ref_dsti_1.html

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

L=size(f,1);
W=size(f,2);

if L==1
  c=f;
  return;
end;

R=1/sqrt(2)*[zeros(1,L,assert_classname(f));...
	     eye(L);
	     zeros(1,L,assert_classname(f));...
	     -flipud(cast(eye(L),assert_classname(f)))];

c=i*R'*dft(R*f);




