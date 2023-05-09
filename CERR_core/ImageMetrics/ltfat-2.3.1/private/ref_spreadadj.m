function cadj=ref_spreadadj(coef);
%-*- texinfo -*-
%@deftypefn {Function} ref_spreadadj
%@verbatim
%REF_SPREADADJ  Symbol of adjoint preading function.
%   Usage: cadj=ref_spreadadj(c);
%
%   cadj=SPREADADJ(c) will compute the symbol cadj of the spreading
%   operator that is the adjoint of the spreading operator with symbol c.
%
%   The algorithm converts the symbol to the matrix representation,
%   adjoints its, and finds its spreading function.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_spreadadj.html}
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
  

L=size(coef,1);

T=tfmat('spread',coef);
cadj=spreadfun(T');




