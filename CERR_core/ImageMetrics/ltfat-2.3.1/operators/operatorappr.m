function Opout=operatorappr(Op,T)
%-*- texinfo -*-
%@deftypefn {Function} operatorappr
%@verbatim
%OPERATORAPPR  Best approximation by operator
%   Usage: c=operatorappr(Op,K);
%
%   Opout=OPERATORAPPR(Opin,T) computes the an operator Opout of the
%   same type as Opin that best approximates the matrix T in the
%   Frobenious norm of the matrix (the Hilbert-Schmidt norm of the
%   operator).
%
%   For some operator classes, the approximation is always exact, so that
%   operator(Opout,f) computes the exact same result as T'*f.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/operators/operatorappr.html}
%@seealso{operatornew, operator, operatoreigs}
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
    s=framemulappr(Op.Fa,Op.Fs,T);
    Opout=operatornew('framemul',Op.Fa,Op.Fs,s);
  case 'spread'
    s=spreadfun(T);
    Opout=operatornew('spread',s);
end;

  

