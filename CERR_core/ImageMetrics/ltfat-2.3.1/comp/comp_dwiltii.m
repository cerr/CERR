function [coef]=comp_dwiltii(coef2,a)
%-*- texinfo -*-
%@deftypefn {Function} comp_dwiltii
%@verbatim
%COMP_DWILT  Compute Discrete Wilson transform.
%   
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_dwiltii.html}
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

coef=zeros(2*M,N/2,W,assert_classname(coef2));


% ---- m is zero ---------
coef(1,:,:)=coef2(1,1:2:N,:);

% --- m is odd ----------
coef(2:2:M,:,:)    = i/sqrt(2)*(coef2(2:2:M,1:2:N,:)+coef2(2*M:-2:M+2,1:2:N,:));
coef(M+2:2:2*M,:,:)= 1/sqrt(2)*(coef2(2:2:M,2:2:N,:)-coef2(2*M:-2:M+2,2:2:N,:));

% --- m is even ---------
coef(3:2:M,:,:)=     1/sqrt(2)*(coef2(3:2:M,1:2:N,:)-coef2(2*M-1:-2:M+2,1:2:N,:));
coef(M+3:2:2*M,:,:)= i/sqrt(2)*(coef2(3:2:M,2:2:N,:)+coef2(2*M-1:-2:M+2,2:2:N,:));

% --- m is nyquest ------
if mod(M,2)==0
  coef(M+1,:,:) = i*coef2(M+1,2:2:N,:);
else
  coef(M+1,:,:) = i*coef2(M+1,1:2:N,:);
end;

coef=reshape(coef,M*N,W);





