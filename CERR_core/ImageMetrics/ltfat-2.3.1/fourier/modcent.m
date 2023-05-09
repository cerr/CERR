function x=modcent(x,r);
%-*- texinfo -*-
%@deftypefn {Function} modcent
%@verbatim
%MODCENT  Centered modulo
%   Usage:  y=modcent(x,r);
%
%   MODCENT(x,r) computes the modulo of x in the range [-r/2,r/2[.
%
%   As an example, to compute the modulo of x in the range [-pi,pi[ use
%   the call:
%
%     y = modcent(x,2*pi);
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/fourier/modcent.html}
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

x=mod(x,r);  
idx=x>r/2;
x(idx)=x(idx)-r;

