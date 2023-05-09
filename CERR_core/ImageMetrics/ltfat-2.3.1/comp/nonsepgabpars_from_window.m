function [g,L,info] = nonsepgabpars_from_window(g,a,M,lt,L,callfun)
%-*- texinfo -*-
%@deftypefn {Function} nonsepgabpars_from_window
%@verbatim
%NONSEPGABPARS_FROM_WINDOW  Compute g and L from window
%   Usage: [g,g.info,L] = gabpars_from_window(f,g,a,M,lt,L);
%
%   Use this function if you know a window and a lattice
%   for the NONSEPDGT. The function will calculate a transform length L and
%   evaluate the window g into numerical form.
%
%   If the transform length is unknown (as it usually is unless explicitly
%   specified by the user), set L to be [] in the input to this function.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/nonsepgabpars_from_window.html}
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
  
if nargin<6
  stacknames=dbstack;  
  callfun=stacknames(2).name;
end;

if isempty(L)
  if isnumeric(g)
    L=length(g);
  else
    L=dgtlength(1,a,M,lt);
  end;
else
  Lcheck=dgtlength(L,a,M,lt);
  if Lcheck~=L
    error('%s: Invalid transform size L',upper(mfilename));
  end;
end;

[g,info] = comp_window(g,a,M,L,lt,'NONSEPGABDUAL');

if (info.isfir)  
  if info.istight
    g=g/sqrt(2);
  end;  
end;

