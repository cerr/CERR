function [coef]=comp_dwiltiv(coef2,a)
%-*- texinfo -*-
%@deftypefn {Function} comp_dwiltiv
%@verbatim
%COMP_DWILTIV  Compute Discrete Wilson transform type IV.
%   
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_dwiltiv.html}
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

M=size(coef2,1)/2;
N=size(coef2,2);
W=size(coef2,3);
L=N*a;

coef=zeros(M,N,W,assert_classname(coef2));

% --- m is even ---------
coef(1:2:M,1:2:N,:)= 1/sqrt(2)*(exp(-i*pi/4)*coef2(1:2:M,1:2:N,:)+exp(-i*pi*3/4)*coef2(2*M:-2:M+1,1:2:N,:));
coef(1:2:M,2:2:N,:)= 1/sqrt(2)*(exp(i*pi/4)*coef2(1:2:M,2:2:N,:)+exp(i*pi*3/4)*coef2(2*M:-2:M+1,2:2:N,:));

% --- m is odd ----------
coef(2:2:M,1:2:N,:)= 1/sqrt(2)*(exp(i*pi/4)*coef2(2:2:M,1:2:N,:)+exp(i*pi*3/4)*coef2(2*M-1:-2:M+1,1:2:N,:));
coef(2:2:M,2:2:N,:)= 1/sqrt(2)*(exp(-i*pi/4)*coef2(2:2:M,2:2:N,:)+exp(-i*pi*3/4)*coef2(2*M-1:-2:M+1,2:2:N,:));

coef=reshape(coef,M*N,W);


