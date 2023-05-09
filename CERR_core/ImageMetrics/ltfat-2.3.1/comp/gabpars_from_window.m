function [g,L,info] = gabpars_from_window(g,a,M,L,callfun)
%-*- texinfo -*-
%@deftypefn {Function} gabpars_from_window
%@verbatim
%GABPARS_FROM_WINDOW  Compute g and L from window
%   Usage: [g,g.info,L] = gabpars_from_window(f,g,a,M);
%
%   Use this function if you know a window and a lattice
%   for the DGT. The function will calculate a transform length L and
%   evaluate the window g into numerical form.
%
%   If the transform length is unknown (as it usually is unless explicitly
%   specified by the user), set L to be [] in the input to this function.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/gabpars_from_window.html}
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
  
if nargin<5
  stacknames=dbstack;  
  callfun=stacknames(2).name;
end;

assert_squarelat(a,M,1,callfun,0);

if ~isempty(L)
  if (prod(size(L))~=1 || ~isnumeric(L))
    error('%s: L must be a scalar',callfun);
  end;
  
  if rem(L,1)~=0
    error('%s: L must be an integer',callfun);
  end;
end;

if isnumeric(g)
  Lwindow=length(g);
else
  Lwindow=0;
end;


if isempty(L)
  % Smallest length transform.
  Lsmallest=lcm(a,M);

  % Choose a transform length larger than both the length of the
  % signal and the window.
  L=ceil(Lwindow/Lsmallest)*Lsmallest;
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

[g,info]=gabwin(g,a,M,L,[0 1],'callfun',callfun);




