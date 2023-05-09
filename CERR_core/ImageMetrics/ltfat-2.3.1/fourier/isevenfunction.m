function t=isevenfunction(f,varargin);
%-*- texinfo -*-
%@deftypefn {Function} isevenfunction
%@verbatim
%ISEVENFUNCTION  True if function is even
%   Usage:  t=isevenfunction(f);
%           t=isevenfunction(f,tol);
%
%   ISEVENFUNCTION(f) returns 1 if f is whole point even. Otherwise it
%   returns 0.
%
%   ISEVENFUNCTION(f,tol) does the same, using the tolerance tol to measure
%   how large the error between the two parts of the vector can be. Default
%   is 1e-10.
%
%   Adding the flag 'hp' as the last argument does the same for half point
%   even functions.
%  
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/fourier/isevenfunction.html}
%@seealso{middlepad, peven}
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
  
%   AUTHOR : Peter L. Soendergaard
%   TESTING: OK
%   REFERENCE: OK

if nargin<1
  error('Too few input parameters.');
end;

if size(f,2)>1
  if size(f,1)>1
    error('f must be a vector');
  else
    % f was a row vector.
    f=f(:);
  end;
end;

% Define initial values for flags
definput.flags.centering = {'wp','hp'};
definput.keyvals.tol     = 1e-10; 

[flags,keyvals,tol]=ltfatarghelper({'tol'},definput,varargin);

L=size(f,1);

if flags.do_wp
  % Determine middle point of sequence.
  if rem(L,2)==0
    middle=L/2;
  else
    middle=(L+1)/2;
  end;
  
  % Relative norm of difference between the parts of the signal.
  d=norm(f(2:middle)-conj(flipud(f(L-middle+2:L))))/norm(f);
else
  
  middle=floor(L/2);
  
  d=norm(f(1:middle)-conj(flipud(f(L-middle+1:L))))/norm(f);

end;

% Return true if d less than tolerance.
t=d<=tol;

