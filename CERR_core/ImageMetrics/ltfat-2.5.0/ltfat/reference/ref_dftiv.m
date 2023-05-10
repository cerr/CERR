function c=ref_dftiv(f)
%REF_DFT  Reference Discrete Fourier Transform Type IV
%   Usage:  c=ref_dftiv(f);
%
%   This is highly experimental!
%
%   Url: http://ltfat.github.io/doc/reference/ref_dftiv.html

% Copyright (C) 2005-2022 Peter L. Soendergaard <peter@sonderport.dk> and others.
% This file is part of LTFAT version 2.5.0
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

L=size(f,1);
W=size(f,2);

% Create weights.
w=sqrt(1/L);

% Create transform matrix.
F=zeros(L);

for m=0:L-1
  for n=0:L-1
    F(m+1,n+1)=w*exp(2*pi*i*(m+.5)*(n+.5)/L);
  end;
end;

% Compute coefficients.
c=F'*f;



