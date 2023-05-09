function cout=col2diag(cin)
%-*- texinfo -*-
%@deftypefn {Function} col2diag
%@verbatim
%COL2DIAG  Move columns of a matrix to diagonals
%   Usage:  cout=col2diag(cin);
%
%   COL2DIAG(cin) will rearrange the elements in the square matrix cin so
%   that columns of cin appears as diagonals. Column number n will appear
%   as diagonal number -n and L-n, where L is the size of the matrix.
%
%   The function is its own inverse.
%
%   COL2DIAG performs the underlying coordinate transform for spreading
%   function and Kohn-Nirenberg calculus in the finite, discrete setting.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/col2diag.html}
%@seealso{spreadop, spreadfun, tconv}
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
  
%   AUTHOR : Peter L. Soendergaard.
%   TESTING: TEST_SPREAD
%   REFERENCE: OK

% Assert correct input.
complainif_argnonotinrange(nargin,1,1,mfilename);

if ndims(cin)~=2 || size(cin,1)~=size(cin,2)
  error('Input matrix must be square.');
end;

if ~isnumeric(cin)
  error('Input must be numerical.');
end;

cout=comp_col2diag(full(cin));


