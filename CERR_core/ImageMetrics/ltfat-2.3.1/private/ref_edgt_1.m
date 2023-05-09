function c=ref_edgt_1(f,g,a,M)
%-*- texinfo -*-
%@deftypefn {Function} ref_edgt_1
%@verbatim
%REF_EDGT_1   Reference Even Discrete Gabor transform by DGT
%   Usage  c=ref_edgt(f,g,a,M);
%
%   The input window must be odd-centered of length 2L.
%
%   M must be even
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_edgt_1.html}
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

L=size(f,1);
W=size(f,2);

N=L/a;
M=L/b;

clong=ref_dgtii([f;flipud(f)],g,a,2*b);

c=zeros(M*N,W);

% The coefficient array is stacked from:
% - The first M/2 coefficients of the first time shift.
% - The body of the coefficients 
% - The first M/2 coefficients of the last time shift.

c(:,:)=[clong(1:M/2,:); ...
        clong(M+1:M*N+M/2,:)];

% Scale the first coefficients correctly
c(1,:)=c(1,:)/sqrt(2);
c(M*(N-1)+M/2+1,:)=c(M*(N-1)+M/2+1,:)/sqrt(2);



