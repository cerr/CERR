function f=rand_hpe(varargin)
%-*- texinfo -*-
%@deftypefn {Function} rand_hpe
%@verbatim
%RAND_HPE  Random HPE even function.
%   Usage:  f=rand_hpe(s);
%
%   RAND_HPE(s) generates an array of size s, which is HPE along the
%   first dimension.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/testing/rand_hpe.html}
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

if isnumeric(varargin);
  s=varargin;
else
  s=cell2mat(varargin);
end;


if length(s)==1
  error('To avoid confusion, the size must be at least two-dimensional.');
end;

shalf=s;

shalf(1)=floor(shalf(1)/2);

f=(randn(shalf)-.5)+(randn(shalf)-.5)*i;

if rem(s(1),2)==0
  f=[f;flipud(conj(f))];
else
  f=[f; ...
     randn([1 s(2:end)])-.5; ...
     flipud(conj(f))];
end;


