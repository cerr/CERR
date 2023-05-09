function x = ref_pcg(A, b, x, tol)
if nargin < 3
    x = b;
    tol = 1e-10;
end
if nargin < 4
    tol = 1e-10;
end

if isa(A,'function_handle')
r = b - A(x);
else
r = b - A * x;
end
p = r;
rsold = norm(r)^2;
if rsold < tol^2, return; end

disp('Starting iterations')
for i = 1:length(b)
    if isa(A,'function_handle')
        Ap = A(p);
    else
        Ap = A * p;
    end
    alpha = rsold / (p' * Ap);
    x = x + alpha * p;
    r = r - alpha * Ap;
    rsnew = norm(r)^2;
    if rsnew < tol^2, break; end
    p = r + (rsnew / rsold) * p;
    rsold = rsnew;
    fprintf('Iter %d, err=%.6f\n',i,rsnew);
end
%-*- texinfo -*-
%@deftypefn {Function} ref_pcg
%@verbatim
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_pcg.html}
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
end
