function coef=spreadfun(T)
%-*- texinfo -*-
%@deftypefn {Function} spreadfun
%@verbatim
%SPREADFUN  Spreading function of a matrix
%   Usage:  c=spreadfun(T);
%
%   SPREADFUN(T) computes the spreading function of the operator T,
%   represented as a matrix. The spreading function represent the operator T*
%   as a weighted sum of time-frequency shifts. See the help text for
%   SPREADOP for the exact definition.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/operators/spreadfun.html}
%@seealso{spreadop, tconv, spreadinv, spreadadj}
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

complainif_argnonotinrange(nargin,1,1,mfilename);

if ndims(T)>2 || size(T,1)~=size(T,2)
    error('Input symbol T must be a square matrix.');
end;

L=size(T,1);

% The 'full' appearing on the next line is to guard the mex file.
coef=comp_col2diag(full(T));

coef=fft(coef)/L;


