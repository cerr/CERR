function [V,D]=spreadeigs(K,coef);
%-*- texinfo -*-
%@deftypefn {Function} spreadeigs
%@verbatim
%SPREADEIGS  Eigenpairs of Spreading operator
%   Usage: h=spreadeigs(K,c);
%
%   SPREADEIGS(K,c) computes the K largest eigenvalues and eigen-
%   vectors of the spreading operator with symbol c.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/operators/spreadeigs.html}
%@seealso{tconv, spreadfun, spreadinv, spreadadj}
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

complainif_argnonotinrange(nargin,2,2,mfilename);

if ndims(coef)>2 || size(coef,1)~=size(coef,2)
    error('Input symbol coef must be a square matrix.');
end;

L=size(coef,1);

% This version explicitly constucts the matrix representation T
% and then applies this matrix as the final step.
coef=fft(coef);
  
T=zeros(L);
for ii=0:L-1
  for jj=0:L-1
    T(ii+1,jj+1)=coef(ii+1,mod(ii-jj,L)+1);
  end;
end;

if nargout==2
  doV=1;
else
  doV=0;
end;

if doV
  [V,D]=eig(T);
else
  D=eig(T);
end;

