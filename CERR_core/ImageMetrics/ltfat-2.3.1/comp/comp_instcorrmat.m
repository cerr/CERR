function R = comp_instcorrmat(f, g);
%-*- texinfo -*-
%@deftypefn {Function} comp_instcorrmat
%@verbatim
%COMP_INSTCORRMAT Compute instantaneous correlation matrix
%   Usage R = comp_instcorrmat(f, g);
%
%   Input parameters:
%         f,g    : Input vectors of the same length.
%
%   Output parameters:
%         R      : Instantaneous correlation matrix.
%
%   
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_instcorrmat.html}
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

% AUTHOR: Jordy van Velthoven

if ~all(size(f)==size(g))
  error('%s: f and g must have the same size.', upper(mfilename));
end

Ls = size(f, 1);

if ~all(mod(Ls,2) == 0)
 f = postpad(f, Ls+1);
 g = postpad(g, Ls+1);
end
 
	
R = zeros(Ls,Ls,assert_classname(f,g));

for l = 0 : Ls-1;
   m = -min([Ls-l, l, round(Ls/2)-1]) : min([Ls-l, l, round(Ls/2)-1]);
   R(mod(Ls+m,Ls)+1, l+1) =  f(mod(l+m, Ls)+1).*conj(g(mod(l-m, Ls)+1));
end

R = R(1:Ls, 1:Ls);

