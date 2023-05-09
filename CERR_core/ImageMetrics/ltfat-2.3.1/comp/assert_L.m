function [b,N,L]=assert_L(Ls,Lwindow,L,a,M,callfun)
%-*- texinfo -*-
%@deftypefn {Function} assert_L
%@verbatim
%ASSERT_L  Validate lattice and window size.
%   Usage:  [b,N,L]=assert_L(Ls,Lwindow,L,a,M,callfun);
%
%   Input parameters:
%         Ls      : Length of signal (see below).
%         Lwindow : Length of window.
%         L       : Specified length of transform (may be [])
%         a       : Length of time shift.
%         M       : Number of modulations.
%         callfun : Name of calling function.
%   Output parameters:
%         b       : Length of frequency shift.
%         N       : Number of translations.
%         L       : Transform length.         
%
%  Calculate a minimal transform length, or verify a user specified
%  input length.
%
%  The routine assumes that a and M has already been checked. use
%  assert_squarelat for this.
%
%  If the window length is not yet determined, it is safe to pass Lwindow=0
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/assert_L.html}
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

if ~isempty(L)
  if (prod(size(L))~=1 || ~isnumeric(L))
    error([callfun,': L must be a scalar']);
  end;
  
  if rem(L,1)~=0
    error([callfun,': L must be an integer']);
  end;
end;

% Length of window must be dividable by M.
if rem(Lwindow,M)~=0
    error('%s: Length of window must be dividable by M = %i.',...
          callfun,M);
end;

if isempty(L)
  % Smallest length transform.
  Lsmallest=lcm(a,M);

  % Choose a transform length larger than both the length of the
  % signal and the window.
  % The ",1" is to always get a transform of at least Lsmallest
  L=ceil(max([Ls,Lwindow,1])/Lsmallest)*Lsmallest;
else

  if rem(L,M)~=0
    error('%s: The length of the transform must be divisable by M = %i',...
          callfun,M);
  end;

  if rem(L,a)~=0
    error('%s: The length of the transform must be divisable by a = %i',...
          callfun,a);
  end;

  if L<Lwindow
    error('%s: Window is too long.',callfun);
  end;

end;

b=L/M;
N=L/a;



