function f=spcrand(n1,n2,p);
%SPCRAND   Sparse Random complex numbers for testing.
%   Usage: f=sptester_crand(n1,n2,p);
%
%   Url: http://ltfat.github.io/doc/testing/spcrand.html

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

% Make a random real valued matrix, extract the indices, put complex
% numbers in and recollect.
f=sprand(n1,n2,p);

[row,col,val]=find(f);

L=numel(val);
val=rand(L,1)-.5+i*(rand(L,1)-.5);

f=sparse(row,col,val,n1,n2);


