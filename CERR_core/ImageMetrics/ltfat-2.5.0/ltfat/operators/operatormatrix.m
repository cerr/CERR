function T=operatormatrix(Op)
%OPERATORMATRIX  Matrix representation of an operator
%   Usage: T=operatormatrix(Op);
%
%   T=OPERATORMATRIX(Op) returns the matrix representation T of the
%   operator Op. The operator object Op must have been created using
%   OPERATORNEW.
%
%   See also: operatornew, operator, operatoreigs
%
%   Url: http://ltfat.github.io/doc/operators/operatormatrix.html

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

if nargin<1
  error('%s: Too few input parameters.',upper(mfilename));
end;

if ~isstruct(Op)
  error('%s: First argument must be a operator definition structure.',upper(mfilename));
end;

T=operator(Op,eye(Op.L));

