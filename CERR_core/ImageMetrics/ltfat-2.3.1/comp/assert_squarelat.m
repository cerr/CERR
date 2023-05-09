function assert_squarelat(a,M,R,callfun,flag)
%-*- texinfo -*-
%@deftypefn {Function} assert_squarelat
%@verbatim
%ASSERT_SQUARELAT  Validate lattice and window size.
%   Usage:  assert_squarelat(a,M,R,callfun,flag);
%
%   Input parameters:
%         a       : Length of time shift.
%         M       : Number of modulations.
%         R       : Number of multiwindows.
%         callfun : Name of calling function.
%         flag    : See below.
%         
%  if flag>0 test if system is at least critically sampled.
%
%  This routine deliberately checks the validity of M before a, such
%  that it can be used for DWILT etc., where you just pass a=M.
%
%  
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/assert_squarelat.html}
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
if nargin==4
  flag=0;
end;

if  (prod(size(M))~=1 || ~isnumeric(M))
  error('%s: M must be a scalar',callfun);
end;

if (prod(size(a))~=1 || ~isnumeric(a))
  error('%s: a must be a scalar',callfun);
end;

if rem(M,1)~=0
  error('%s: M must be an integer',callfun);
end;

if rem(a,1)~=0
  error('%s: a must be an integer',callfun);
end;

if flag>0
  if a>M*R
    error('%s: The lattice must not be undersampled',callfun);
  end;
end;



