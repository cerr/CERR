function p = quadtfdist(f, q)
%-*- texinfo -*-
%@deftypefn {Function} quadtfdist
%@verbatim
%QUADTFDIST Quadratic time-frequency distribution
%   Usage p = quadtfdist(f, q);
%
%   Input parameters:
%         f  : Input vector:w
%         q  : Kernel
%
%   Output parameters:
%         p  : Quadratic time-frequency distribution
% 
%   For an input vector of length L, the kernel should be a L x L matrix.
%   QUADTFDIST(f, q); computes a discrete quadratic time-frequency 
%   distribution. 
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/quadratic/quadtfdist.html}
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

complainif_notenoughargs(nargin, 2, 'QUADTFDIST');

[M,N] = size(q);

if ~all(M==N)
  error('%s: The kernel should be a square matrix.', upper(mfilename));
end

[f,~,Ls,W,~,permutedsize,order]=assert_sigreshape_pre(f,[],[],upper(mfilename));

p = comp_quadtfdist(f, q);


