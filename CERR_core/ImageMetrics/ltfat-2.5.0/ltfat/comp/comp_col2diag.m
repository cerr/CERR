function cout=comp_col2diag(cin);
%COMP_COL2DIAG  transforms columns to diagonals (in a special way)
%
%  This function transforms the first column to the main diagonal. The
%  second column to the first side-diagonal below the main diagonal and so
%  on. 
% 
%  This way fits well the connection of matrix and spreading function, see
%  spreadfun.
%
%  This function is its own inverse.
%
%   Url: http://ltfat.github.io/doc/comp/comp_col2diag.html

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

%   AUTHOR : Peter L. Søndergaard.
%   TESTING: OK
%   REFERENCE: OK

L=size(cin,1);
cout=zeros(L,assert_classname(cin));

jj=(0:L-1).';
for ii=0:L-1
  cout(ii+1,:)=cin(ii+1,mod(ii-jj,L)+1);
end;




