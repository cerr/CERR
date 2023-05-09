function outsig=operatoradj(Op,insig);
%-*- texinfo -*-
%@deftypefn {Function} operatoradj
%@verbatim
%OPERATORADJ  Apply the adjoint of an operator
%   Usage: c=operatoradj(Op,f);
%
%   c=OPERATORADJ(Op,f) applies the adjoint operator of the operator Op*
%   to the input signal f.  The operator object Op must have been
%   created using OPERATORNEW.
%
%   If f is a matrix, the transform will be applied along the columns
%   of f. If f is an N-D array, the transform will be applied along
%   the first non-singleton dimension.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/operators/operatoradj.html}
%@seealso{operatornew, operator, ioperator}
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
  
if nargin<2
  error('%s: Too few input parameters.',upper(mfilename));
end;

if ~isstruct(Op)
  error('%s: First argument must be a operator definition structure.',upper(mfilename));
end;

switch(Op.type)
  case 'framemul'
    outsig=framemuladj(insig,Op.Fa,Op.Fs,Op.s);
  case 'spread'
    outsig=spreadadj(insig,Op.s);
end;

  

