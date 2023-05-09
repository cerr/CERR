function out=spreadinv(p1,p2);
%-*- texinfo -*-
%@deftypefn {Function} spreadinv
%@verbatim
%SPREADINV  Apply inverse spreading operator
%   Usage: h=spreadinv(f,c);
%
%   SPREADINV(c) computes the symbol of the inverse of the spreading
%   operator with symbol c.
%
%   SPREADINV(f,c) applies the inverse of the spreading operator with
%   symbol c to the input signal f.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/operators/spreadinv.html}
%@seealso{spreadfun, tconv, spreadfun, spreadadj}
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

complainif_argnonotinrange(nargin,1,2,mfilename);

% FIXME This function should handle sparse symbols, and use a iterative
% method instead of creating the full symbol.

% FIXME This function should handle f though comp_reshape_pre and post.
if nargin==1
  coef=p1;
else
  f=p1;
  coef=p2;
end;

if ndims(coef)>2 || size(coef,1)~=size(coef,2)
    error('Input symbol T must be a square matrix.');
end;

L=size(coef,1);

% Create a matrix representation of the operator.
coef=ifft(full(coef))*L;
T=comp_col2diag(coef);

if nargin==1
  
  % Calculate the inverse symbol.
  out=spreadfun(inv(T));
    
else
  
  out=T\f;
  
end;

