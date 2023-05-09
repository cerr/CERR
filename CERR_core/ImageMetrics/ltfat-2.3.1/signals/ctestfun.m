function [ftest]=ctestfun(L)
%-*- texinfo -*-
%@deftypefn {Function} ctestfun
%@verbatim
%CTESTFUN  Complex 1-D test function
%   Usage:  ftest=ctestfun(L);
%
%   CTESTFUN(L) returns a test signal consisting of a superposition of a
%   chirp and an indicator function.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/signals/ctestfun.html}
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

ftest=zeros(L,1);

sp=round(L/4);
lchirp=round(L/2);
ftest(sp+1:sp+lchirp)=exp(2*i*linspace(0,2*pi*sqrt(lchirp)/10,lchirp).^2)';

s=round(L*7/16);
l=round(L/16);
ftest(s:s+l)=ftest(s:s+l)+ones(l+1,1);


