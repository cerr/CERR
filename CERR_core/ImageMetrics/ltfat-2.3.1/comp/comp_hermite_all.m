function y = comp_hermite_all(n, x)
%-*- texinfo -*-
%@deftypefn {Function} comp_hermite_all
%@verbatim
%COMP_HERMITE_ALL  Compute all Hermite functions up to an order
%   Usage:  y = hermite_fun_all(n, x);
%
%   This function evaluates the Hermite functions
%   of degree 0 through n-1 at the vector x.
%   The functions are normalized to have the L^2 norm
%   on (-inf,inf) equal to one. No effort is made to 
%   avoid unerflow during recursion.	
%   
%   Input parameters: 
%     n     : the number of Hermite functions
%     x     : the vector of arguments
%
%   Output parameters:
%     y     : the values of the first n Hermite functions at 
%             the nodes x
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_hermite_all.html}
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


%   T. Hrycak, Mar. 22, 2006
%   Last modified   July 17, 2007
%
%
%       

rt = 1 / sqrt(sqrt(pi));

%     
%     conducting the recursion.
%

y = zeros(length(x), n);

y(:, 1) = rt * exp(-0.5 * x.^2);
if n > 1
   y(:, 2) = rt * sqrt(2) * x .* exp(-0.5 * x.^2);
end
for k = 2:n-1
        y(:, k+1) = sqrt(2)*x.*y(:, k) - sqrt(k-1)*y(:, k-1);
        y(:, k+1) = y(:, k+1)/sqrt(k);
end



