function outsig=operatoreigs(Op,K,varargin);
%-*- texinfo -*-
%@deftypefn {Function} operatoreigs
%@verbatim
%OPERATOREIGS  Apply the adjoint of an operator
%   Usage: c=operatoreigs(Op,K);
%
%   [V,D]=OPERATOREIGS(Op,K) computes the K largest eigenvalues and
%   eigenvectors of the operator Op to the input signal f.  The operator
%   object Op must have been created using OPERATORNEW.
%
%   If K is empty, then all eigenvalues/pairs will be returned.
%
%   D=OPERATOREIGS(...) computes only the eigenvalues.
%
%   OPERATOREIGS takes the following parameters at the end of the line of input
%   arguments:
%
%     'tol',t      Stop if relative residual error is less than the
%                  specified tolerance. Default is 1e-9 
%
%     'maxit',n    Do at most n iterations.
%
%     'iter'       Call eigs to use an iterative algorithm.
%
%     'full'       Call eig to solve the full problem.
%
%     'auto'       Use the full method for small problems and the
%                  iterative method for larger problems. This is the
%                  default. 
%
%     'crossover',c
%                  Set the problem size for which the 'auto' method
%                  switches. Default is 200.
%
%     'print'      Display the progress.
%
%     'quiet'      Don't print anything, this is the default.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/operators/operatoreigs.html}
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
    outsig=framemuleigs(Op.Fa,Op.Fs,Op.s,K,varargin{:});
  case 'spread'
    outsig=spreadeigs(K,Op.s);
end;

  

