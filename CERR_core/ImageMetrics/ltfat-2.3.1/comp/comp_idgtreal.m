function f=comp_idgtreal(coef,g,a,M,lt,phasetype)
%-*- texinfo -*-
%@deftypefn {Function} comp_idgtreal
%@verbatim
%COMP_IDGTREAL  Compute IDGTREAL
%   Usage:  f=comp_idgtreal(c,g,a,M,lt,phasetype);
%
%   Input parameters:
%         c     : Array of coefficients.
%         g     : Window function.
%         a     : Length of time shift.
%         M     : Number of modulations.
%         lt    : lattice type
%   Output parameters:
%         f     : Signal.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_idgtreal.html}
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

%   AUTHOR : Peter L. Soendergaard.
%   TESTING: TEST_DGT
%   REFERENCE: OK

N=size(coef,2);
L=N*a;

if lt(2)==1
    f = comp_isepdgtreal(coef,g,L,a,M,phasetype);
else
    % Quinqux lattice
    f=comp_inonsepdgtreal_quinqux(coef,g,a,M);
end;


