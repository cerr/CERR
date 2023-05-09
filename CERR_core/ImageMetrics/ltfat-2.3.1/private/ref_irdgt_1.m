function f=ref_irdgt_1(c,g,a,M)
%-*- texinfo -*-
%@deftypefn {Function} ref_irdgt_1
%@verbatim
%REF_IRDGT_1  Reference Inverse Real DGT by fac. and IRDFT
%   Usage:  c=ref_rdgt_1(f,g,a,M);
%
%   Compute the factorization and use IRDFT
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/reference/ref_irdgt_1.html}
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

L=size(g,1);
R=size(g,2);
W=size(c,2);

%M=L/b;
N=L/a;

% Apply ifft to the coefficients.
c=ref_irdft(reshape(c,M,N*R*W));

gf = comp_wfac(g,a,M);      
f = comp_idgt_fw(c,gf,L,a,M);



