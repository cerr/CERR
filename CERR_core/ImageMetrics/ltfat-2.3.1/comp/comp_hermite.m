function y = comp_hermite(n, x);
%-*- texinfo -*-
%@deftypefn {Function} comp_hermite
%@verbatim
%COMP_HERMITE   Compute sampling of continuous Hermite function.
%   Usage:  y = comp_hermite(n, x);
%
%   COMP_HERMITE(n, x) evaluates the n-th Hermite function at the vector x.
%   The function is normalized to have the L^2(-inf,inf) norm equal to one.
%
%   A minimal effort is made to avoid underflow in recursion.
%   If used to evaluate the Hermite quadratures, it works for n <= 2400
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_hermite.html}
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

% AUTHOR:
%   T. Hrycak, Oct 5, 2005
%   Last modified July 17, 2007


rt = 1 / sqrt(sqrt(pi));

if n == 0
  y = rt * exp(-0.5 * x.^2);
end
if n == 1
  y = rt * sqrt(2) * x .* exp(-0.5 * x.^2);
end

%     
%     if n > 2, conducting the recursion.
%

if n >= 2
  ef = exp(-0.5 * (x.^2) / (n+1));
  tmp1 = rt * ef;
  tmp2 = rt * sqrt(2) * x .* (ef.^2);
  for k = 2:n
    y = sqrt(2)*x.*tmp2 - sqrt(k-1)*tmp1 .* ef;
    y = ef .* y / sqrt(k);
    tmp1 = tmp2;
    tmp2 = y;
  end
end
  





